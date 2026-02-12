class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_amount

  default_scope { order(:position, :id) }

  # Accept common user-entered formats for decimals (commas, currency symbols,
  # spaces, thousand separators). This avoids surprising "doesn't work" behavior
  # when a user's locale uses commas for decimals.
  def quantity=(value)
    super(normalize_decimal_input(value))
  end

  def rate=(value)
    super(normalize_decimal_input(value))
  end

  private

  def normalize_decimal_input(value)
    return value unless value.is_a?(String)

    s = value.strip
    return s if s.blank?

    # Keep digits, separators, and minus sign; strip currency symbols/spaces.
    s = s.gsub(/[^\d.,-]/, "")

    last_dot = s.rindex(".")
    last_comma = s.rindex(",")

    if last_dot && last_comma
      # Treat the last occurring separator as the decimal separator.
      if last_comma > last_dot
        # "1.234,56" => thousands "." removed, decimal "," -> "."
        s = s.delete(".").sub(",", ".")
      else
        # "1,234.56" => thousands "," removed
        s = s.delete(",")
      end
    elsif last_comma && !last_dot
      # "12,34" => "12.34"
      s = s.tr(",", ".")
    end

    s
  end

  def calculate_amount
    self.amount = (quantity || 0) * (rate || 0)
  end
end
