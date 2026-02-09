class AddPaymentDetailsToInvoices < ActiveRecord::Migration[7.2]
  def change
    add_column :invoices, :payment_methods, :jsonb, default: [], null: false
  end
end
