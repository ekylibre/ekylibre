class CreateSaasSubscription < ActiveRecord::Migration[5.0]
  def change
    create_table :saas_subscriptions do |t|
      t.references :entity, null: false, index: true
      t.references :entity_payment_method, index: true
      t.references :catalog_item, index: true
      t.string :name
      t.string :status
      t.string :tenant_name
      t.text :description
      t.references :partner, index: true
      t.datetime :started_at, null: false
      t.datetime :stopped_at
      t.datetime :canceled_at
      t.datetime :trial_started_at
      t.datetime :trial_stopped_at
      t.stamps
    end

    create_table :entity_payment_methods do |t|
      t.references :entity, null: false, index: true
      t.string :name
      t.string :nature
      t.text :description
      t.datetime :expired_at
      t.stamps
    end

    add_foreign_key :saas_subscriptions, :entities, column: :entity_id
    add_foreign_key :saas_subscriptions, :entity_payment_methods, column: :entity_payment_method_id
    add_foreign_key :saas_subscriptions, :entities, column: :partner_id
    add_foreign_key :saas_subscriptions, :catalog_items, column: :catalog_item_id
    add_provider_to :saas_subscriptions
    add_provider_to :catalog_items
    add_provider_to :catalogs
    add_foreign_key :entity_payment_methods, :entities, column: :entity_id
    add_provider_to :entity_payment_methods
    add_provider_to :events

  end

  def add_provider_to(table_name)
    if column_exists? table_name, :provider
      remove_column table_name, :provider, :jsonb
      add_column table_name, :provider, :jsonb, default: {}
    else
      add_column table_name, :provider, :jsonb, default: {}
    end

    reversible do |dir|
      dir.up do
        query("CREATE INDEX #{table_name.to_s.singularize}_provider_index ON #{table_name} USING gin ((provider -> 'vendor'), (provider -> 'name'), (provider -> 'id'))")
      end
      dir.down do
        query("DROP INDEX #{table_name.to_s.singularize}_provider_index")
      end
    end
  end
end
