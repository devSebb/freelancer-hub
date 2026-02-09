FactoryBot.define do
  factory :client do
    association :user
    sequence(:name) { |n| "Client #{n}" }
    sequence(:email) { |n| "client#{n}@example.com" }
    phone { "+1 555 123 4567" }
    company { "Test Company" }
    language { :en }

    trait :spanish do
      language { :es }
    end
  end
end
