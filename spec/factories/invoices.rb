FactoryBot.define do
  factory :invoice do
    association :user
    due_date { 30.days.from_now }
    discount_type { :no_discount }
    discount_value { 0 }

    trait :with_client do
      association :client
    end

    trait :with_items do
      after(:create) do |invoice|
        create(:invoice_item, invoice: invoice, description: "Service 1", quantity: 1, rate: 1000)
        create(:invoice_item, invoice: invoice, description: "Service 2", quantity: 2, rate: 500)
      end
    end

    trait :sent do
      association :client
      status { :sent }
      sent_at { 1.day.ago }
    end

    trait :paid do
      association :client
      status { :paid }
      sent_at { 5.days.ago }
    end

    trait :with_discount_percent do
      discount_type { :percent }
      discount_value { 10 }
    end

    trait :with_discount_fixed do
      discount_type { :fixed }
      discount_value { 100 }
    end

    trait :with_deposit do
      deposit_percent { 50 }
    end
  end
end
