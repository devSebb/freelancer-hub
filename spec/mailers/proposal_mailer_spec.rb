require "rails_helper"

RSpec.describe ProposalMailer, type: :mailer do
  describe "proposal_sent" do
    let(:user) { create(:user, business_name: "Test Business") }
    let(:client) { create(:client, user: user, email: "client@example.com", name: "Test Client", language: :en) }
    let(:proposal) { create(:proposal, :sent, user: user, client: client, title: "Test Proposal") }
    let(:mail) { ProposalMailer.proposal_sent(proposal) }

    it "renders the headers" do
      expect(mail.subject).to eq("Proposal: Test Proposal")
      expect(mail.to).to eq(["client@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Test Business")
      expect(mail.body.encoded).to include("Test Client")
    end
  end

  describe "proposal_accepted" do
    let(:user) { create(:user, email: "freelancer@example.com", language: :en) }
    let(:client) { create(:client, user: user) }
    let(:proposal) { create(:proposal, :accepted, user: user, client: client, title: "Accepted Proposal") }
    let(:mail) { ProposalMailer.proposal_accepted(proposal) }

    it "renders the headers" do
      expect(mail.subject).to include("Accepted Proposal")
      expect(mail.to).to eq(["freelancer@example.com"])
    end

    it "includes signature details" do
      expect(mail.body.encoded).to include(proposal.signature_name)
    end
  end

  describe "proposal_viewed" do
    let(:user) { create(:user, email: "freelancer@example.com", language: :en) }
    let(:client) { create(:client, user: user, name: "Viewing Client") }
    let(:proposal) { create(:proposal, :viewed, user: user, client: client, title: "Viewed Proposal") }
    let(:mail) { ProposalMailer.proposal_viewed(proposal) }

    it "renders the headers" do
      expect(mail.subject).to include("Viewed Proposal")
      expect(mail.to).to eq(["freelancer@example.com"])
    end

    it "includes client name" do
      expect(mail.body.encoded).to include("Viewing Client")
    end
  end
end
