class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_amount

  default_scope { order(:position, :id) }

  private

  def calculate_amount
    self.amount = (quantity || 0) * (rate || 0)
  end
end
