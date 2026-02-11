class WebhookEvent < ApplicationRecord
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :event_created_at, presence: true
end
