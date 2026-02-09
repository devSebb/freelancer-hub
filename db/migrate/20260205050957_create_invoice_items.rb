class CreateInvoiceItems < ActiveRecord::Migration[7.2]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.decimal :rate, precision: 10, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :invoice_items, [ :invoice_id, :position ]
  end
end
