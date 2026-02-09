class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company
      t.integer :language, default: 0, null: false
      t.string :portal_token
      t.datetime :portal_token_expires_at

      t.timestamps
    end

    add_index :clients, :portal_token, unique: true
    add_index :clients, [ :user_id, :email ], unique: true
  end
end
