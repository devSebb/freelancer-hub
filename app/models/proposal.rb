class Proposal < ApplicationRecord
  belongs_to :user
  belongs_to :client, optional: true

  enum :status, {
    draft: 0,
    sent: 1,
    viewed: 2,
    accepted: 3,
    declined: 4,
    expired: 5
  }, default: :draft

  enum :pricing_type, {
    fixed: 0,
    hourly: 1
  }, default: :fixed

  validates :title, presence: true
  validates :share_token, presence: true, uniqueness: true
  validates :client, presence: true, unless: :draft?
  validates :amount, presence: true, numericality: { greater_than: 0 }, if: :fixed?
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }, if: :hourly?

  before_validation :generate_share_token, on: :create

  scope :for_user, ->(user) { where(user: user) }
  scope :active, -> { where.not(status: [ :declined, :expired ]) }

  def total_amount
    if fixed?
      amount || 0
    elsif hourly?
      (hourly_rate || 0) * (estimated_hours || 0)
    else
      0
    end
  end

  def mark_as_sent!
    return unless draft?

    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_viewed!(ip_address: nil)
    return if viewed? || accepted? || declined?
    return unless sent?

    update!(status: :viewed, viewed_at: Time.current)
  end

  def accept!(signature_name:, signature_ip:)
    return unless sent? || viewed?

    update!(
      status: :accepted,
      signature_name: signature_name,
      signature_ip: signature_ip,
      signature_at: Time.current
    )
  end

  def expired?
    return false if expires_at.nil?
    return true if status == "expired"

    expires_at < Time.current
  end

  def can_be_viewed?
    (sent? || viewed?) && !expired?
  end

  def can_be_accepted?
    (sent? || viewed?) && !expired? && !accepted? && !declined?
  end

  def public_url
    Rails.application.routes.url_helpers.public_proposal_url(share_token)
  end

  private

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(32)
  end
end
