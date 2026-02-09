FactoryBot.define do
  factory :invoice_item do
    association :invoice
    sequence(:description) { |n| "Service Item #{n}" }
    quantity { 1 }
    rate { 100.00 }
  end
end
