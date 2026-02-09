class CreateProposals < ActiveRecord::Migration[7.2]
  def change
    create_table :proposals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :client, null: true, foreign_key: true
      t.string :title, null: false
      t.text :scope
      t.text :deliverables
      t.date :timeline_start
      t.date :timeline_end
      t.integer :pricing_type, default: 0, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.decimal :estimated_hours, precision: 10, scale: 2
      t.text :terms
      t.datetime :expires_at
      t.integer :status, default: 0, null: false
      t.string :share_token, null: false
      t.string :signature_name
      t.string :signature_ip
      t.datetime :signature_at
      t.datetime :viewed_at
      t.datetime :sent_at

      t.timestamps
    end

    add_index :proposals, :share_token, unique: true
    add_index :proposals, :status
  end
end
