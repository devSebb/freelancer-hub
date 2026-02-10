class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :send_invoice, :export_pdf, :preview_pdf ]

  def index
    @pagy, @invoices = pagy(current_user.invoices.includes(:client).order(created_at: :desc), items: 20)
  end

  def show
  end

  def new
    @invoice = current_user.invoices.build
    @invoice.due_date = 30.days.from_now.to_date

    # Pre-select client if provided
    @invoice.client_id = params[:client_id] if params[:client_id].present?

    # Create from proposal if provided
    if params[:proposal_id].present?
      proposal = current_user.proposals.find_by(id: params[:proposal_id])
      if proposal
        @invoice.proposal = proposal
        @invoice.client = proposal.client
        # Add a line item from the proposal
        @invoice.invoice_items.build(
          description: proposal.title,
          quantity: proposal.hourly? ? (proposal.estimated_hours || 1) : 1,
          rate: proposal.hourly? ? proposal.hourly_rate : proposal.amount
        )
      end
    end

    # Add an empty line item if none exist
    @invoice.invoice_items.build if @invoice.invoice_items.empty?
  end

  def create
    @invoice = current_user.invoices.build(invoice_params)

    if @invoice.save
      redirect_to @invoice, notice: t("invoices.created")
    else
      @invoice.invoice_items.build if @invoice.invoice_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @invoice.draft?
      redirect_to @invoice, alert: t("invoices.cannot_edit")
      return
    end
    @invoice.invoice_items.build if @invoice.invoice_items.empty?
  end

  def update
    unless @invoice.draft?
      redirect_to @invoice, alert: t("invoices.cannot_edit")
      return
    end

    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: t("invoices.updated")
    else
      @invoice.invoice_items.build if @invoice.invoice_items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: t("invoices.deleted")
  end

  def send_invoice
    unless @invoice.draft?
      redirect_to @invoice, alert: t("invoices.already_sent")
      return
    end

    if @invoice.client.nil?
      redirect_to edit_invoice_path(@invoice), alert: t("invoices.select_client_first")
      return
    end

    if @invoice.invoice_items.empty?
      redirect_to edit_invoice_path(@invoice), alert: t("invoices.add_items_first")
      return
    end

    @invoice.mark_as_sent!
    InvoiceMailer.invoice_sent(@invoice).deliver_later

    redirect_to @invoice, notice: t("invoices.sent")
  end

  def preview_pdf
    @preview = true
    template_style = params[:style].presence || "modern"
    template_style = "modern" unless %w[modern classic minimal].include?(template_style)

    locale = @invoice.client&.language || current_user.language || I18n.default_locale

    html = I18n.with_locale(locale) do
      render_to_string(
        template: "pdf/invoices/show",
        layout: "pdf",
        locals: {
          invoice: @invoice,
          user: @invoice.user,
          client: @invoice.client,
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
    locale = @invoice.client&.language || current_user.language || I18n.default_locale

    html = I18n.with_locale(locale) do
      render_to_string(
        template: "pdf/invoices/show",
        layout: "pdf",
        locals: {
          invoice: @invoice,
          user: @invoice.user,
          client: @invoice.client,
          template_style: template_style,
          show_powered_by: !current_user.pro?
        }
      )
    end

    pdf = Grover.new(html, format: "A4", print_background: true).to_pdf
    filename = "#{@invoice.invoice_number}-#{Date.current}.pdf"

    send_data pdf, filename: filename, type: "application/pdf", disposition: "attachment"
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id,
      :proposal_id,
      :due_date,
      :discount_type,
      :discount_value,
      :deposit_percent,
      :tax_notes,
      :notes,
      invoice_items_attributes: [ :id, :description, :quantity, :rate, :position, :_destroy ],
      payment_methods: [ :type, :label, :bank_name, :account_number, :routing_number, :email, :handle, :address, :instructions ]
    )
  end
end
