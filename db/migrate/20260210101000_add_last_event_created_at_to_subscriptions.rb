class AddLastEventCreatedAtToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :last_event_created_at, :datetime
  end
end
