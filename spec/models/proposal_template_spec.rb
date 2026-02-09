require "rails_helper"

RSpec.describe ProposalTemplate, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:content) }

    context "uniqueness" do
      subject { create(:proposal_template) }
      it { should validate_uniqueness_of(:name).scoped_to(:user_id) }
    end
  end

  describe ".from_proposal" do
    let(:user) { create(:user) }
    let(:proposal) do
      create(:proposal,
        user: user,
        scope: "Build a website",
        deliverables: "Homepage, About page",
        terms: "50% upfront",
        pricing_type: :fixed,
        amount: 5000
      )
    end

    it "creates a template from a proposal" do
      template = ProposalTemplate.from_proposal(proposal, name: "Web Project Template")

      expect(template.user).to eq(user)
      expect(template.name).to eq("Web Project Template")
      expect(template.content["scope"]).to eq("Build a website")
      expect(template.content["deliverables"]).to eq("Homepage, About page")
      expect(template.content["terms"]).to eq("50% upfront")
      expect(template.content["pricing_type"]).to eq("fixed")
      expect(template.content["amount"].to_f).to eq(5000.0)
    end

    it "creates a template from hourly proposal" do
      hourly_proposal = create(:proposal, :hourly,
        user: user,
        hourly_rate: 150,
        estimated_hours: 40
      )

      template = ProposalTemplate.from_proposal(hourly_proposal, name: "Hourly Template")

      expect(template.content["pricing_type"]).to eq("hourly")
      expect(template.content["hourly_rate"].to_f).to eq(150.0)
      expect(template.content["estimated_hours"].to_f).to eq(40.0)
    end
  end

  describe "#apply_to" do
    let(:template) { create(:proposal_template) }
    let(:proposal) { build(:proposal, user: template.user) }

    it "applies template content to a proposal" do
      template.apply_to(proposal)

      expect(proposal.scope).to eq(template.content["scope"])
      expect(proposal.deliverables).to eq(template.content["deliverables"])
      expect(proposal.terms).to eq(template.content["terms"])
    end
  end
end
