class ProposalMailer < ApplicationMailer
  def proposal_sent(proposal)
    @proposal = proposal
    @client = proposal.client
    @user = proposal.user
    @proposal_url = public_proposal_url(@proposal.share_token)

    # Use client's preferred language
    I18n.with_locale(@client.language) do
      mail(
        to: @client.email,
        subject: t("mailers.proposal_sent.subject", title: @proposal.title)
      )
    end
  end

  def proposal_accepted(proposal)
    @proposal = proposal
    @client = proposal.client
    @user = proposal.user

    # Notify freelancer in their language
    I18n.with_locale(@user.language) do
      mail(
        to: @user.email,
        subject: t("mailers.proposal_accepted.subject", title: @proposal.title)
      )
    end
  end

  def proposal_viewed(proposal)
    @proposal = proposal
    @client = proposal.client
    @user = proposal.user

    # Notify freelancer in their language
    I18n.with_locale(@user.language) do
      mail(
        to: @user.email,
        subject: t("mailers.proposal_viewed.subject", title: @proposal.title)
      )
    end
  end
end
