FactoryBot.define do
  factory :proposal do
    association :user
    sequence(:title) { |n| "Project Proposal #{n}" }
    scope { "Build a web application with the following features..." }
    deliverables { "- Feature 1\n- Feature 2\n- Feature 3" }
    terms { "Standard terms and conditions apply." }
    pricing_type { :fixed }
    amount { 5000.00 }
    timeline_start { 1.week.from_now }
    timeline_end { 2.months.from_now }

    trait :hourly do
      pricing_type { :hourly }
      amount { nil }
      hourly_rate { 150.00 }
      estimated_hours { 40 }
    end

    trait :with_client do
      association :client
    end

    trait :sent do
      association :client
      status { :sent }
      sent_at { 1.day.ago }
    end

    trait :viewed do
      association :client
      status { :viewed }
      sent_at { 2.days.ago }
      viewed_at { 1.day.ago }
    end

    trait :accepted do
      association :client
      status { :accepted }
      sent_at { 3.days.ago }
      viewed_at { 2.days.ago }
      signature_name { "John Doe" }
      signature_ip { "192.168.1.1" }
      signature_at { 1.day.ago }
    end

    trait :expired do
      association :client
      status { :expired }
      expires_at { 1.day.ago }
    end

    trait :expiring_soon do
      expires_at { 3.days.from_now }
    end
  end
end
