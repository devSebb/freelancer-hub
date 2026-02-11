class CreateWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.string :stripe_subscription_id
      t.datetime :event_created_at, null: false
      t.datetime :processed_at

      t.timestamps
    end

    add_index :webhook_events, :stripe_event_id, unique: true
    add_index :webhook_events, :stripe_subscription_id
  end
end
