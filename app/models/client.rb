class Client < ApplicationRecord
  belongs_to :user
  has_many :proposals, dependent: :nullify
  has_many :invoices, dependent: :nullify

  enum :language, { en: 0, es: 1 }, default: :en

  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :user_id, message: "already exists for this account" }

  before_create :generate_portal_token

  def generate_portal_token!
    generate_portal_token
    save!
  end

  private

  def generate_portal_token
    self.portal_token = SecureRandom.urlsafe_base64(32)
  end
end
