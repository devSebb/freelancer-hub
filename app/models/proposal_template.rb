class ProposalTemplate < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :content, presence: true

  # Fields that can be stored in template content
  TEMPLATE_FIELDS = %w[
    scope
    deliverables
    terms
    pricing_type
    amount
    hourly_rate
    estimated_hours
  ].freeze

  def self.from_proposal(proposal, name:)
    new(
      user: proposal.user,
      name: name,
      content: extract_content(proposal)
    )
  end

  def self.extract_content(proposal)
    TEMPLATE_FIELDS.each_with_object({}) do |field, hash|
      value = proposal.send(field)
      hash[field] = value if value.present?
    end
  end

  def apply_to(proposal)
    content.each do |field, value|
      proposal.send("#{field}=", value) if proposal.respond_to?("#{field}=")
    end
    proposal
  end
end
