class UpdateStockAccountingAttributes < ActiveRecord::Migration
  def change
    # variant
    rename_column :product_nature_variants, :number, :work_number
    add_column :product_nature_variants, :number, :string, index: true
    add_reference :product_nature_variants, :stock_account, index: true
    add_reference :product_nature_variants, :movement_stock_account, index: true
    # remove stock_account, movement_stock_account to parcel_items
    remove_column :parcel_items, :stock_account_id, :string, index: true
    remove_column :parcel_items, :movement_stock_account_id, :string, index: true
    # remove stock_account, movement_stock_account to intervention_parameters
    remove_column :intervention_parameters, :stock_account_id, :string, index: true
    remove_column :intervention_parameters, :movement_stock_account_id, :string, index: true
    # remove stock_account, movement_stock_account to inventory_items
    remove_column :inventory_items, :stock_account_id, :string, index: true
    remove_column :inventory_items, :movement_stock_account_id, :string, index: true
  end
end
