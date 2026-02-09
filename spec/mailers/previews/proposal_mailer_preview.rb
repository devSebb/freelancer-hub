# Preview all emails at http://localhost:3000/rails/mailers/proposal_mailer
class ProposalMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/proposal_mailer/proposal_sent
  def proposal_sent
    ProposalMailer.proposal_sent
  end

end
