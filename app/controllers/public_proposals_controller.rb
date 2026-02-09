class PublicProposalsController < ApplicationController
  skip_before_action :set_locale
  before_action :set_proposal
  before_action :check_viewable, only: :show
  before_action :check_acceptable, only: :accept

  layout "public"

  def show
    # Set locale based on client's language preference
    I18n.locale = @proposal.client&.language&.to_sym || I18n.default_locale

    # Mark as viewed if this is the first view
    @proposal.mark_as_viewed!(ip_address: request.remote_ip)
  end

  def accept
    I18n.locale = @proposal.client&.language&.to_sym || I18n.default_locale

    if params[:signature_name].blank?
      flash.now[:alert] = t("public_proposals.signature_required")
      render :show, status: :unprocessable_entity
      return
    end

    @proposal.accept!(
      signature_name: params[:signature_name],
      signature_ip: request.remote_ip
    )

    # Notify freelancer
    ProposalMailer.proposal_accepted(@proposal).deliver_later

    redirect_to public_proposal_path(@proposal.share_token), notice: t("public_proposals.accepted_success")
  end

  private

  def set_proposal
    @proposal = Proposal.find_by!(share_token: params[:token])
  end

  def check_viewable
    unless @proposal.can_be_viewed?
      render :expired, status: :gone
    end
  end

  def check_acceptable
    unless @proposal.can_be_accepted?
      redirect_to public_proposal_path(@proposal.share_token), alert: t("public_proposals.cannot_accept")
    end
  end
end
