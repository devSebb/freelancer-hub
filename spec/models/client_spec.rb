require 'rails_helper'

RSpec.describe Client, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:client) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }

    it "validates email uniqueness scoped to user" do
      user = create(:user)
      create(:client, user: user, email: "test@example.com")
      duplicate = build(:client, user: user, email: "test@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("already exists for this account")
    end

    it "allows same email for different users" do
      user1 = create(:user)
      user2 = create(:user)
      create(:client, user: user1, email: "test@example.com")
      client2 = build(:client, user: user2, email: "test@example.com")

      expect(client2).to be_valid
    end
  end

  describe "callbacks" do
    it "generates portal_token on create" do
      client = create(:client)
      expect(client.portal_token).to be_present
      expect(client.portal_token.length).to eq(43) # base64 encoded 32 bytes
    end
  end

  describe "#generate_portal_token!" do
    it "regenerates the portal token" do
      client = create(:client)
      old_token = client.portal_token

      client.generate_portal_token!

      expect(client.portal_token).not_to eq(old_token)
    end
  end
end
