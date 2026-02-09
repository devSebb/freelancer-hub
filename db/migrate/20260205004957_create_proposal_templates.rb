class CreateProposalTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :proposal_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :content, null: false, default: {}

      t.timestamps
    end

    add_index :proposal_templates, [ :user_id, :name ], unique: true
  end
end
