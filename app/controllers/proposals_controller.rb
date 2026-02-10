class ProposalsController < ApplicationController
  before_action :set_proposal, only: [ :show, :edit, :update, :destroy, :send_proposal, :save_as_template, :export_pdf, :preview_pdf ]

  def index
    @pagy, @proposals = pagy(current_user.proposals.includes(:client).order(created_at: :desc), items: 20)
  end

  def show
    @templates = current_user.proposal_templates.order(:name)
  end

  def new
    @proposal = current_user.proposals.build
    @proposal.client_id = params[:client_id] if params[:client_id].present?

    # Apply template if specified
    if params[:template_id].present?
      template = current_user.proposal_templates.find_by(id: params[:template_id])
      template&.apply_to(@proposal)
    end

    @templates = current_user.proposal_templates.order(:name)
  end

  def create
    @proposal = current_user.proposals.build(proposal_params)

    if @proposal.save
      redirect_to @proposal, notice: t("proposals.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @proposal.draft?
      redirect_to @proposal, alert: t("proposals.cannot_edit")
    end
  end

  def update
    unless @proposal.draft?
      redirect_to @proposal, alert: t("proposals.cannot_edit")
      return
    end

    if @proposal.update(proposal_params)
      redirect_to @proposal, notice: t("proposals.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @proposal.destroy
    redirect_to proposals_path, notice: t("proposals.deleted")
  end

  def send_proposal
    unless @proposal.draft?
      redirect_to @proposal, alert: t("proposals.already_sent")
      return
    end

    if @proposal.client.nil?
      redirect_to edit_proposal_path(@proposal), alert: t("proposals.select_client_first")
      return
    end

    @proposal.mark_as_sent!
    ProposalMailer.proposal_sent(@proposal).deliver_later

    redirect_to @proposal, notice: t("proposals.sent")
  end

  def save_as_template
    template_name = params[:template_name].presence || "#{@proposal.title} Template"
    template = ProposalTemplate.from_proposal(@proposal, name: template_name)

    if template.save
      redirect_to @proposal, notice: t("proposal_templates.created_from_proposal")
    else
      redirect_to @proposal, alert: template.errors.full_messages.join(", ")
    end
  end

  def preview_pdf
    @preview = true
    template_style = params[:style].presence || "modern"
    template_style = "modern" unless %w[modern classic minimal].include?(template_style)

    locale = @proposal.client&.language || current_user.language || I18n.default_locale

    html = I18n.with_locale(locale) do
      render_to_string(
        template: "pdf/proposals/show",
        layout: "pdf",
        locals: {
          proposal: @proposal,
          user: @proposal.user,
          client: @proposal.client,
          template_style: template_style,
          show_powered_by: !current_user.pro?
        }
      )
    end

    render html: html.html_safe, layout: false
  end

  def export_pdf
    template_style = params[:style].presence || "modern"
    template_style = "modern" unless %w[modern classic minimal].include?(template_style)

    # Use client's language for the PDF if available
    locale = @proposal.client&.language || current_user.language || I18n.default_locale

    html = I18n.with_locale(locale) do
      render_to_string(
        template: "pdf/proposals/show",
        layout: "pdf",
        locals: {
          proposal: @proposal,
          user: @proposal.user,
          client: @proposal.client,
          template_style: template_style,
          show_powered_by: !current_user.pro?
        }
      )
    end

    pdf = Grover.new(html, format: "A4", print_background: true).to_pdf
    filename = "#{@proposal.title.parameterize}-proposal-#{Date.current}.pdf"

    send_data pdf, filename: filename, type: "application/pdf", disposition: "attachment"
  end

  private

  def set_proposal
    @proposal = current_user.proposals.find(params[:id])
  end

  def proposal_params
    params.require(:proposal).permit(
      :client_id,
      :title,
      :scope,
      :deliverables,
      :timeline_start,
      :timeline_end,
      :pricing_type,
      :amount,
      :hourly_rate,
      :estimated_hours,
      :terms,
      :expires_at
    )
  end
end
