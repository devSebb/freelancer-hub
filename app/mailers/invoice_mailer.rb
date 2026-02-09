class InvoiceMailer < ApplicationMailer
  def invoice_sent(invoice)
    @invoice = invoice
    @client = invoice.client
    @user = invoice.user
    @invoice_url = public_invoice_url(@invoice.share_token)

    # Use client's preferred language
    I18n.with_locale(@client.language) do
      mail(
        to: @client.email,
        subject: t("mailers.invoice_sent.subject", invoice_number: @invoice.invoice_number)
      )
    end
  end

  def invoice_paid(invoice)
    @invoice = invoice
    @client = invoice.client
    @user = invoice.user

    # Notify freelancer in their language
    I18n.with_locale(@user.language) do
      mail(
        to: @user.email,
        subject: t("mailers.invoice_paid.subject", invoice_number: @invoice.invoice_number)
      )
    end
  end
end
