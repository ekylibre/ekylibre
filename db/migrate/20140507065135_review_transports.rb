class ReviewTransports < ActiveRecord::Migration
  def change
    remove_column :transports, :amount
    remove_column :transports, :pretax_amount
    rename_column :transports, :description, :annotation
    rename_column :transports, :purchase_id, :transporter_purchase_id

    add_column :outgoing_deliveries, :with_transport, :boolean, null: false, default: false
    remove_column :outgoing_deliveries, :mode_id
    add_column :outgoing_deliveries, :mode, :string
    execute "UPDATE outgoing_deliveries SET mode = 'ex_works'"
    change_column_null :outgoing_deliveries, :mode, false

    remove_column :outgoing_delivery_items, :source_product_id
    change_column_default :outgoing_delivery_items, :population, nil
    change_column_null    :outgoing_delivery_items, :population, true
    add_column :outgoing_delivery_items, :shape, :geometry, srid: 4326
    add_column :outgoing_delivery_items, :net_mass, :decimal, precision: 19, scale: 4
    add_column :outgoing_delivery_items, :container_id, :integer

    add_column :incoming_deliveries, :net_mass, :decimal, precision: 19, scale: 4
    remove_column :incoming_deliveries, :mode_id
    add_column :incoming_deliveries, :mode, :string
    execute "UPDATE incoming_deliveries SET mode = 'ex_works'"
    change_column_null :outgoing_deliveries, :mode, false

    change_column_default :incoming_delivery_items, :population, nil
    change_column_null    :incoming_delivery_items, :population, true
    add_column :incoming_delivery_items, :shape, :geometry, srid: 4326
    add_column :incoming_delivery_items, :net_mass, :decimal, precision: 19, scale: 4

    drop_table :incoming_delivery_modes

    drop_table :outgoing_delivery_modes
  end
end
