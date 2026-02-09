class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :client, foreign_key: true
      t.references :proposal, foreign_key: true
      t.string :invoice_number, null: false
      t.integer :discount_type, default: 0
      t.decimal :discount_value, precision: 10, scale: 2, default: 0
      t.text :tax_notes
      t.decimal :deposit_percent, precision: 5, scale: 2
      t.date :due_date
      t.text :notes
      t.integer :status, null: false, default: 0
      t.string :share_token, null: false
      t.datetime :sent_at

      t.timestamps
    end

    add_index :invoices, :invoice_number
    add_index :invoices, :share_token, unique: true
    add_index :invoices, :status
    add_index :invoices, [ :user_id, :invoice_number ], unique: true
  end
end
