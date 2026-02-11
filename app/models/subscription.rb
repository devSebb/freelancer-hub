class Subscription < ApplicationRecord
  ACTIVE_STATUSES = %w[active trialing].freeze

  belongs_to :user

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_price_id, presence: true
  validates :status, presence: true

  scope :active_or_trialing, -> { where(status: ACTIVE_STATUSES) }
end
