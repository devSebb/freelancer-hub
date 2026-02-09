FactoryBot.define do
  factory :proposal_template do
    association :user
    sequence(:name) { |n| "Template #{n}" }
    content do
      {
        "scope" => "Standard project scope...",
        "deliverables" => "- Deliverable 1\n- Deliverable 2",
        "terms" => "Standard terms and conditions.",
        "pricing_type" => "fixed",
        "amount" => "5000.00"
      }
    end

    trait :hourly do
      content do
        {
          "scope" => "Hourly project scope...",
          "deliverables" => "- Deliverable 1\n- Deliverable 2",
          "terms" => "Standard terms and conditions.",
          "pricing_type" => "hourly",
          "hourly_rate" => "150.00",
          "estimated_hours" => "40"
        }
      end
    end
  end
end
