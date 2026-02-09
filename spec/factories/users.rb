FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    name { "Test User" }
    business_name { "Test Business" }
    language { :en }

    trait :spanish do
      language { :es }
    end
  end
end
