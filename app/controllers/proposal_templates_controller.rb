class ProposalTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_template_limit, only: [ :new, :create, :from_proposal ]

  def index
    @templates = current_user.proposal_templates.order(:name)
  end

  def show
  end

  def new
    @template = current_user.proposal_templates.build
  end

  def create
    @template = current_user.proposal_templates.build(template_params)

    if @template.save
      redirect_to proposal_templates_path, notice: t("proposal_templates.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to proposal_templates_path, notice: t("proposal_templates.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to proposal_templates_path, notice: t("proposal_templates.deleted")
  end

  # POST /proposal_templates/from_proposal/:proposal_id
  def from_proposal
    proposal = current_user.proposals.find(params[:proposal_id])

    @template = ProposalTemplate.from_proposal(proposal, name: params[:name] || "#{proposal.title} Template")

    if @template.save
      redirect_to proposal_templates_path, notice: t("proposal_templates.created_from_proposal")
    else
      redirect_to proposal_path(proposal), alert: @template.errors.full_messages.join(", ")
    end
  end

  private

  def ensure_template_limit
    return unless current_user.at_limit?(:templates)

    redirect_to pricing_path(limit: :templates), alert: t(
      "billing.limits.messages.templates_total",
      usage: current_user.usage_for(:templates),
      limit: current_user.limit_for(:templates)
    )
  end

  def set_template
    @template = current_user.proposal_templates.find(params[:id])
  end

  def template_params
    params.require(:proposal_template).permit(:name, content: {})
  end
end
