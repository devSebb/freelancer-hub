class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :language, { en: 0, es: 1 }, default: :en

  has_many :clients, dependent: :destroy
  has_many :proposals, dependent: :destroy
  has_many :proposal_templates, dependent: :destroy
  has_many :invoices, dependent: :destroy

  has_one_attached :logo

  validates :logo, content_type: [ "image/png", "image/jpeg", "image/webp" ],
                   size: { less_than: 2.megabytes }

  # Check if user has a Pro subscription
  # TODO: Update this when subscriptions table is implemented
  # Should be: subscriptions.active.pro.exists?
  def pro?
    false
  end
end
