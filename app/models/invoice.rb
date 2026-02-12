class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :client, optional: true
  belongs_to :proposal, optional: true

  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: :all_blank

  enum :status, {
    draft: 0,
    sent: 1,
    partially_paid: 2,
    paid: 3,
    overdue: 4
  }, default: :draft

  enum :discount_type, {
    no_discount: 0,
    percent: 1,
    fixed: 2
  }, default: :no_discount, prefix: :discount

  validates :invoice_number, presence: true, uniqueness: { scope: :user_id }
  validates :share_token, presence: true, uniqueness: true
  validates :client, presence: true, unless: :draft?

  before_validation :generate_share_token, on: :create
  before_validation :generate_invoice_number, on: :create

  scope :for_user, ->(user) { where(user: user) }
  scope :not_draft, -> { where.not(status: :draft) }

  # Calculate subtotal (sum of all line items)
  def subtotal
    invoice_items.sum(&:amount)
  end

  # Calculate discount amount
  def discount_amount
    return 0 if discount_no_discount? || discount_value.blank? || discount_value.zero?

    if discount_percent?
      subtotal * (discount_value / 100)
    else
      discount_value
    end
  end

  # Total after discount
  def total
    subtotal - discount_amount
  end

  # Deposit amount (if deposit_percent is set)
  def deposit_amount
    return 0 if deposit_percent.blank? || deposit_percent.zero?
    total * (deposit_percent / 100)
  end

  # Final payment amount (after deposit)
  def final_amount
    total - deposit_amount
  end

  # Check if invoice has deposit requirement
  def has_deposit?
    deposit_percent.present? && deposit_percent > 0
  end

  def mark_as_sent!
    return unless draft?

    update!(status: :sent, sent_at: Time.current)
  end

  def expired?
    due_date.present? && due_date < Date.current && !paid?
  end

  def can_be_viewed?
    sent? || partially_paid? || paid? || overdue?
  end

  def public_url
    Rails.application.routes.url_helpers.public_invoice_url(share_token)
  end

  # Payment methods helpers
  PAYMENT_METHOD_TYPES = %w[bank_transfer paypal venmo zelle cashapp crypto other].freeze

  # Normalize payment methods into an Array<Hash> regardless of how they were
  # persisted (some forms submit a hash like { "0" => { ... } }).
  def payment_methods
    normalize_payment_methods(super)
  end

  def has_payment_methods?
    payment_methods.present? && payment_methods.any?
  end

  def payment_methods_by_type
    return {} unless has_payment_methods?
    payment_methods.group_by { |pm| pm["type"] }
  end

  # Generate next invoice number for user
  def self.next_invoice_number(user)
    last_invoice = user.invoices.order(created_at: :desc).first
    if last_invoice&.invoice_number&.match?(/^INV-(\d+)$/)
      last_number = last_invoice.invoice_number.match(/^INV-(\d+)$/)[1].to_i
      "INV-#{(last_number + 1).to_s.rjust(4, '0')}"
    else
      "INV-0001"
    end
  end

  private

  def normalize_payment_methods(value)
    methods =
      case value
      when nil
        []
      when Array
        value
      when Hash
        # If this hash already looks like a single payment method, wrap it.
        if value.key?("type") || value.key?(:type)
          [ value ]
        else
          value.values
        end
      else
        Array(value)
      end

    methods.filter_map do |pm|
      pm = pm.to_unsafe_h if pm.respond_to?(:to_unsafe_h)
      next unless pm.is_a?(Hash)

      pm.deep_stringify_keys
    end
  end

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(32)
  end

  def generate_invoice_number
    self.invoice_number ||= self.class.next_invoice_number(user) if user.present?
  end
end
