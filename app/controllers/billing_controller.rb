class BillingController < ApplicationController
  before_action :authenticate_user!

  VALID_TIERS = %w[starter pro].freeze
  VALID_INTERVALS = %w[monthly yearly].freeze

  def checkout
    tier = params[:tier].to_s
    interval = params[:interval].to_s

    unless VALID_TIERS.include?(tier) && VALID_INTERVALS.include?(interval)
      redirect_to pricing_path, alert: t("billing.checkout.invalid_selection")
      return
    end

    price_id = stripe_price_id_for(tier: tier, interval: interval)
    if price_id.blank?
      redirect_to pricing_path, alert: t("billing.checkout.missing_price")
      return
    end

    session = Stripe::Checkout::Session.create(
      mode: "subscription",
      customer: current_user.stripe_customer_id.presence,
      customer_email: current_user.stripe_customer_id.present? ? nil : current_user.email,
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: "#{billing_base_url}#{settings_path(checkout: "success")}",
      cancel_url: "#{billing_base_url}#{pricing_path(interval: interval)}"
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe checkout error: #{e.message}")
    redirect_to pricing_path, alert: t("billing.checkout.unavailable")
  end

  def portal
    if current_user.stripe_customer_id.blank?
      redirect_to settings_path, alert: t("billing.portal.no_customer")
      return
    end

    session = Stripe::BillingPortal::Session.create(
      customer: current_user.stripe_customer_id,
      return_url: "#{billing_base_url}#{settings_path}"
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe portal error: #{e.message}")
    redirect_to settings_path, alert: t("billing.portal.unavailable")
  end

  private

  def billing_base_url
    base = ENV["APP_URL"].presence || request.base_url
    base.to_s.chomp("/")
  end

  def stripe_price_id_for(tier:, interval:)
    case [ tier, interval ]
    when [ "starter", "monthly" ] then ENV["STRIPE_STARTER_MONTHLY_PRICE_ID"]
    when [ "starter", "yearly" ] then ENV["STRIPE_STARTER_YEARLY_PRICE_ID"]
    when [ "pro", "monthly" ] then ENV["STRIPE_PRO_MONTHLY_PRICE_ID"]
    when [ "pro", "yearly" ] then ENV["STRIPE_PRO_YEARLY_PRICE_ID"]
    end
  end
end
