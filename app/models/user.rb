class User < ApplicationRecord
  PLAN_LIMIT_KEYS = {
    clients: :clients,
    proposals: :proposals_per_month,
    invoices: :invoices_per_month,
    templates: :templates
  }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :language, { en: 0, es: 1 }, default: :en

  has_many :clients, dependent: :destroy
  has_many :proposals, dependent: :destroy
  has_many :proposal_templates, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  has_one_attached :logo

  validates :logo, content_type: [ "image/png", "image/jpeg", "image/webp" ],
                   size: { less_than: 2.megabytes }

  def pro?
    active_subscription.present?
  end

  def active_subscription
    subscriptions.active_or_trialing.order(updated_at: :desc).first
  end

  def current_plan_tier
    return :free unless pro?

    price_id = active_subscription&.stripe_price_id
    mapped_tier = self.class.plan_price_mapping[price_id]

    # Until Stripe price IDs are wired in Phase 2, default paid users to Pro.
    mapped_tier&.to_sym || :pro
  end

  def limit_for(resource)
    key = PLAN_LIMIT_KEYS.fetch(resource)
    self.class.plan_tiers.fetch(current_plan_tier).fetch(:limits).fetch(key)
  end

  def usage_for(resource, now: Time.current)
    case resource
    when :clients
      clients.count
    when :templates
      proposal_templates.count
    when :proposals
      proposals.where(created_at: monthly_quota_window(now: now)).count
    when :invoices
      invoices.where(created_at: monthly_quota_window(now: now)).count
    else
      raise ArgumentError, "Unsupported resource: #{resource}"
    end
  end

  def at_limit?(resource, now: Time.current)
    limit = limit_for(resource)
    return false if limit.nil?

    usage_for(resource, now: now) >= limit
  end

  def monthly_quota_window(now: Time.current)
    subscription = active_subscription

    if subscription&.current_period_start.present? && subscription&.current_period_end.present?
      subscription.current_period_start..subscription.current_period_end
    else
      now.utc.beginning_of_month..now.utc.end_of_month
    end
  end

  def self.plan_tiers
    @plan_tiers ||= Rails.application.config_for(:plans).deep_symbolize_keys.fetch(:tiers)
  end

  def self.plan_price_mapping
    configured_mapping = Rails.application.config_for(:plans).fetch("price_id_to_tier", {})
    env_mapping = {
      ENV["STRIPE_STARTER_MONTHLY_PRICE_ID"] => "starter",
      ENV["STRIPE_STARTER_YEARLY_PRICE_ID"] => "starter",
      ENV["STRIPE_PRO_MONTHLY_PRICE_ID"] => "pro",
      ENV["STRIPE_PRO_YEARLY_PRICE_ID"] => "pro"
    }.compact

    configured_mapping.merge(env_mapping)
  end
end
