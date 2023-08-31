class UpdateSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :codes, :jsonb
    add_column :subscriptions, :trial_started_at, :datetime
    add_column :subscriptions, :trial_stopped_at, :datetime
    add_column :subscriptions, :current_period_started_at, :datetime
    add_column :subscriptions, :current_period_stopped_at, :datetime
    add_column :subscriptions, :status, :string
    change_column_null :subscriptions, :stopped_on, true
    add_column :sales, :subscription_id, :integer
  end
end
