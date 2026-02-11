class StripeWebhooksController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    event = construct_event
    return head :bad_request if event.nil?

    webhook_event = WebhookEvent.find_or_initialize_by(stripe_event_id: event.id)
    return head :ok if webhook_event.persisted? && webhook_event.processed_at.present?

    webhook_event.event_type = event.type
    webhook_event.stripe_subscription_id = stripe_subscription_id_from(event)
    webhook_event.event_created_at = Time.at(event.created).utc
    webhook_event.save! if webhook_event.new_record?

    process_event(event)
    webhook_event.update!(processed_at: Time.current)

    head :ok
  rescue ActiveRecord::RecordNotUnique
    head :ok
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.warn("Stripe webhook signature verification failed: #{e.message}")
    head :bad_request
  rescue JSON::ParserError => e
    Rails.logger.warn("Stripe webhook payload parse failed: #{e.message}")
    head :bad_request
  rescue StandardError => e
    Rails.logger.error("Stripe webhook processing error: #{e.class} - #{e.message}")
    head :internal_server_error
  end

  private

  def construct_event
    payload = request.raw_post
    signature = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV["STRIPE_WEBHOOK_SECRET"]
    return nil if secret.blank?

    Stripe::Webhook.construct_event(payload, signature, secret)
  end

  def process_event(event)
    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event)
    when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
      stripe_subscription = event.data.object
      sync_subscription_from_stripe!(
        stripe_subscription: stripe_subscription,
        event_created_at: Time.at(event.created).utc
      )
    when "invoice.payment_succeeded", "invoice.paid", "invoice.payment_failed"
      handle_invoice_event(event)
    else
      Rails.logger.info("Stripe webhook ignored event type: #{event.type}")
    end
  end

  def handle_checkout_completed(event)
    session = event.data.object
    subscription_id = session.subscription
    return if subscription_id.blank?

    user = find_user_for_checkout_session(session)
    return if user.nil?

    stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
    sync_subscription_from_stripe!(
      stripe_subscription: stripe_subscription,
      event_created_at: Time.at(event.created).utc,
      user: user
    )
  end

  def handle_invoice_event(event)
    invoice = event.data.object
    subscription_id = subscription_id_from_invoice(invoice)
    return if subscription_id.blank?

    stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
    sync_subscription_from_stripe!(
      stripe_subscription: stripe_subscription,
      event_created_at: Time.at(event.created).utc
    )
  end

  # Stripe API 2026+ moved subscription id to parent.subscription_details.subscription
  def subscription_id_from_invoice(invoice)
    return invoice.subscription if invoice.respond_to?(:subscription) && invoice.subscription.present?
    return nil unless invoice.respond_to?(:parent) && invoice.parent.present?

    parent = invoice.parent
    return nil unless parent.respond_to?(:subscription_details) && parent.subscription_details.present?

    parent.subscription_details.subscription
  end

  def find_user_for_checkout_session(session)
    customer_id = session.customer
    email = session&.customer_details&.email || session.customer_email

    user = User.find_by(stripe_customer_id: customer_id) if customer_id.present?
    user ||= User.find_by(email: email) if email.present?

    if user.present? && customer_id.present? && user.stripe_customer_id.blank?
      user.update!(stripe_customer_id: customer_id)
    end

    user
  end

  def sync_subscription_from_stripe!(stripe_subscription:, event_created_at:, user: nil)
    user ||= User.find_by(stripe_customer_id: stripe_subscription.customer)
    unless user
      Rails.logger.warn("Stripe webhook: user not found for customer #{stripe_subscription.customer}")
      return
    end

    ActiveRecord::Base.transaction do
      subscription = Subscription.find_or_initialize_by(
        stripe_subscription_id: stripe_subscription.id
      )

      # Ignore out-of-order events that are older than the latest applied event.
      if subscription.last_event_created_at.present? && event_created_at < subscription.last_event_created_at
        Rails.logger.info("Stripe webhook: ignored stale event for #{stripe_subscription.id}")
        return
      end

      if user.stripe_customer_id.blank? && stripe_subscription.customer.present?
        user.update!(stripe_customer_id: stripe_subscription.customer)
      end

      if Subscription::ACTIVE_STATUSES.include?(stripe_subscription.status)
        user.subscriptions.active_or_trialing.where.not(id: subscription.id).find_each do |old_sub|
          old_sub.update!(status: "canceled")
        end
      end

      first_item = stripe_subscription.items.data.first
      subscription.user = user
      subscription.stripe_price_id = first_item&.price&.id || stripe_subscription.plan&.id
      subscription.status = stripe_subscription.status
      subscription.current_period_start = to_utc_time(period_start_from_subscription(stripe_subscription))
      subscription.current_period_end = to_utc_time(period_end_from_subscription(stripe_subscription))
      subscription.cancel_at_period_end = stripe_subscription.cancel_at_period_end
      subscription.last_event_created_at = event_created_at
      subscription.save!
    end
  end

  # Stripe API 2026+ moved current_period_* to the first subscription item
  def period_start_from_subscription(stripe_subscription)
    return stripe_subscription.current_period_start if stripe_subscription.respond_to?(:current_period_start) && stripe_subscription.current_period_start.present?
    first_item = stripe_subscription.items.data.first
    first_item&.respond_to?(:current_period_start) ? first_item.current_period_start : nil
  end

  def period_end_from_subscription(stripe_subscription)
    return stripe_subscription.current_period_end if stripe_subscription.respond_to?(:current_period_end) && stripe_subscription.current_period_end.present?
    first_item = stripe_subscription.items.data.first
    first_item&.respond_to?(:current_period_end) ? first_item.current_period_end : nil
  end

  def stripe_subscription_id_from(event)
    case event.type
    when "checkout.session.completed"
      event.data.object.subscription
    when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
      event.data.object.id
    when "invoice.payment_succeeded", "invoice.paid", "invoice.payment_failed"
      subscription_id_from_invoice(event.data.object)
    end
  end

  def to_utc_time(unix_timestamp)
    return nil if unix_timestamp.blank?

    Time.at(unix_timestamp).utc
  end
end
