class AddAccountingAttributesToParcels < ActiveRecord::Migration
  def change
    # add currency, journal_entry and accounted_at to parcels
    add_column :parcels, :accounted_at, :datetime
    add_column :parcels, :currency, :string
    add_reference :parcels, :journal_entry, index: true
    # add stock_account, movement_stock_account to parcel_items
    add_reference :parcel_items, :stock_account, index: true
    add_reference :parcel_items, :movement_stock_account, index: true
    add_column :parcel_items, :currency, :string
    add_column :parcel_items, :unit_pretax_stock_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    # add currency, journal_entry and accounted_at to interventions
    add_column :interventions, :accounted_at, :datetime
    add_column :interventions, :currency, :string
    add_reference :interventions, :journal_entry, index: true
    # add stock_account, movement_stock_account to intervention_parameters
    add_reference :intervention_parameters, :stock_account, index: true
    add_reference :intervention_parameters, :movement_stock_account, index: true
    add_column :intervention_parameters, :currency, :string
    add_column :intervention_parameters, :unit_pretax_stock_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    # add currency to inventories
    add_column :inventories, :currency, :string
    # add stock_account, movement_stock_account to inventory_items
    add_reference :inventory_items, :stock_account, index: true
    add_reference :inventory_items, :movement_stock_account, index: true
    add_column :inventory_items, :currency, :string
    add_column :inventory_items, :unit_pretax_stock_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
  end
end
