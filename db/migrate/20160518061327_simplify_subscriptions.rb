class SimplifySubscriptions < ActiveRecord::Migration
  def change
    add_column :product_natures, :subscribing, :boolean, null: false, default: false
    add_reference :product_natures, :subscription_nature, index: true
    add_column :product_natures, :subscription_years_count, :integer, null: false, default: 0
    add_column :product_natures, :subscription_months_count, :integer, null: false, default: 0
    add_column :product_natures, :subscription_days_count, :integer, null: false, default: 0

    add_reference :subscriptions, :parent, index: true
    add_column :subscriptions, :swim_lane_uuid, :uuid, index: true

    rename_column :subscriptions, :started_at, :started_on
    change_column :subscriptions, :started_on, :date
    add_index :subscriptions, :started_on

    rename_column :subscriptions, :stopped_at, :stopped_on
    change_column :subscriptions, :stopped_on, :date
    add_index :subscriptions, :stopped_on

    reversible do |d|
      d.up do
        # Convert 'quantity' subscriptions to 'period' subscriptions
        execute "UPDATE subscriptions SET started_on = subscriptions.created_at, stopped_on = subscriptions.created_at + '1 year -1 day'::INTERVAL, custom_fields = JSONB_SET(JSONB_SET(custom_fields, '{first_number}'::TEXT[], TO_JSONB(first_number)), '{last_number}'::TEXT[], TO_JSONB(last_number)) FROM subscription_natures AS n WHERE n.nature = 'quantity'"
        # Force value in quantity
        execute 'UPDATE subscriptions SET quantity = 1 WHERE quantity IS NULL'
        # Configures product data
        execute 'UPDATE product_natures SET subscription_years_count = 1, subscription_nature_id = c.subscription_nature_id, subscribing = TRUE FROM product_nature_categories AS c WHERE c.id = category_id AND c.subscribing'
        # Sets renewal columns
        execute "UPDATE subscriptions SET parent_id = previous.id, swim_lane_uuid = previous.swim_lane_uuid FROM subscriptions AS previous WHERE subscriptions.subscriber_id = previous.subscriber_id AND subscriptions.nature_id = previous.nature_id AND previous.started_on < subscriptions.started_on AND previous.stopped_on = subscriptions.started_on - '1 day'::INTERVAL"
        # Adds UUID for parent only
        execute 'UPDATE subscriptions SET swim_lane_uuid = uuid_generate_v4() WHERE parent_id IS NULL'
        # Copy parent UUID in children of renewal chain
        execute 'WITH RECURSIVE parent_uuid(id, nature_id, uuid) AS (' \
                'SELECT p.id, p.nature_id, p.swim_lane_uuid FROM subscriptions AS p WHERE parent_id IS NULL ' \
                'UNION ALL ' \
                'SELECT s.id, s.nature_id, p.uuid FROM subscriptions AS s JOIN parent_uuid AS p ON (s.nature_id = p.nature_id AND s.parent_id = p.id)' \
                ') ' \
                'UPDATE subscriptions SET swim_lane_uuid = parent.uuid FROM parent_uuid AS parent WHERE parent.id = subscriptions.id AND parent.uuid IS NOT NULL'
      end
      d.down do
        execute "UPDATE subscription_natures SET nature = 'period'"
      end
    end

    change_column :subscriptions, :quantity, :integer, null: false

    change_column_null :subscriptions, :started_on, false
    change_column_null :subscriptions, :stopped_on, false
    change_column_null :subscriptions, :swim_lane_uuid, false

    revert do
      add_column :subscription_natures, :actual_number, :integer
      add_column :subscription_natures, :entity_link_direction, :string
      add_column :subscription_natures, :entity_link_nature, :string
      add_column :subscription_natures, :reduction_percentage, :decimal, precision: 19, scale: 4
      add_column :subscription_natures, :nature, :string
    end

    revert do
      add_reference :subscriptions, :sale, index: true
      add_reference :subscriptions, :product_nature, index: true
      add_column :subscriptions, :first_number, :integer
      add_column :subscriptions, :last_number, :integer
    end

    revert do
      add_column :product_nature_categories, :subscription_duration
      add_reference :product_nature_categories, :subscription_nature, index: true
    end
  end
end
