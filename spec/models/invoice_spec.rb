require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:client).optional }
    it { should belong_to(:proposal).optional }
    it { should have_many(:invoice_items).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:invoice_number) }
    # share_token and invoice_number are auto-generated

    context "when not draft" do
      subject { build(:invoice, :sent) }
      it { should validate_presence_of(:client) }
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, sent: 1, partially_paid: 2, paid: 3, overdue: 4) }
    it { should define_enum_for(:discount_type).with_prefix(:discount).with_values(no_discount: 0, percent: 1, fixed: 2) }
  end

  describe "callbacks" do
    it "generates a share_token before validation on create" do
      invoice = build(:invoice, share_token: nil)
      invoice.valid?
      expect(invoice.share_token).to be_present
    end

    it "generates an invoice_number before validation on create" do
      user = create(:user)
      invoice = build(:invoice, user: user, invoice_number: nil)
      invoice.valid?
      expect(invoice.invoice_number).to eq("INV-0001")
    end

    it "increments invoice numbers" do
      user = create(:user)
      create(:invoice, user: user, invoice_number: "INV-0001")
      invoice = build(:invoice, user: user, invoice_number: nil)
      invoice.valid?
      expect(invoice.invoice_number).to eq("INV-0002")
    end
  end

  describe "#subtotal" do
    it "returns sum of all invoice items" do
      invoice = create(:invoice)
      create(:invoice_item, invoice: invoice, quantity: 2, rate: 100)
      create(:invoice_item, invoice: invoice, quantity: 1, rate: 50)

      expect(invoice.subtotal).to eq(250)
    end
  end

  describe "#discount_amount" do
    it "returns 0 when no discount" do
      invoice = build(:invoice, discount_type: :no_discount)
      expect(invoice.discount_amount).to eq(0)
    end

    it "calculates percentage discount" do
      invoice = create(:invoice, discount_type: :percent, discount_value: 10)
      create(:invoice_item, invoice: invoice, quantity: 1, rate: 1000)

      expect(invoice.discount_amount).to eq(100)
    end

    it "returns fixed discount amount" do
      invoice = create(:invoice, discount_type: :fixed, discount_value: 50)
      create(:invoice_item, invoice: invoice, quantity: 1, rate: 1000)

      expect(invoice.discount_amount).to eq(50)
    end
  end

  describe "#total" do
    it "returns subtotal minus discount" do
      invoice = create(:invoice, discount_type: :percent, discount_value: 10)
      create(:invoice_item, invoice: invoice, quantity: 1, rate: 1000)

      expect(invoice.total).to eq(900)
    end
  end

  describe "#deposit_amount" do
    it "returns 0 when no deposit" do
      invoice = build(:invoice, deposit_percent: nil)
      expect(invoice.deposit_amount).to eq(0)
    end

    it "calculates deposit from total" do
      invoice = create(:invoice, deposit_percent: 50)
      create(:invoice_item, invoice: invoice, quantity: 1, rate: 1000)

      expect(invoice.deposit_amount).to eq(500)
    end
  end

  describe "#final_amount" do
    it "returns total minus deposit" do
      invoice = create(:invoice, deposit_percent: 50)
      create(:invoice_item, invoice: invoice, quantity: 1, rate: 1000)

      expect(invoice.final_amount).to eq(500)
    end
  end

  describe "#has_deposit?" do
    it "returns false when deposit_percent is nil" do
      invoice = build(:invoice, deposit_percent: nil)
      expect(invoice.has_deposit?).to be false
    end

    it "returns false when deposit_percent is 0" do
      invoice = build(:invoice, deposit_percent: 0)
      expect(invoice.has_deposit?).to be false
    end

    it "returns true when deposit_percent is set" do
      invoice = build(:invoice, deposit_percent: 50)
      expect(invoice.has_deposit?).to be true
    end
  end

  describe "#mark_as_sent!" do
    it "changes status from draft to sent" do
      invoice = create(:invoice, :with_client, status: :draft)
      invoice.mark_as_sent!
      expect(invoice.reload).to be_sent
      expect(invoice.sent_at).to be_present
    end

    it "does not change status if already sent" do
      invoice = create(:invoice, :sent)
      original_sent_at = invoice.sent_at
      invoice.mark_as_sent!
      expect(invoice.reload.sent_at).to eq(original_sent_at)
    end
  end
end
