class PublicInvoicesController < ApplicationController
  skip_before_action :set_locale
  before_action :set_invoice

  layout "public"

  def show
    # Set locale based on client's language preference
    I18n.locale = @invoice.client&.language&.to_sym || I18n.default_locale
  end

  private

  def set_invoice
    @invoice = Invoice.find_by!(share_token: params[:token])
  end
end
