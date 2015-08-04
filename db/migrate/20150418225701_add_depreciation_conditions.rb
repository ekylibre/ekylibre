class AddDepreciationConditions < ActiveRecord::Migration
  def change
    rename_column :financial_assets, :charges_account_id, :expenses_account_id

    add_column :product_nature_categories, :financial_asset_depreciation_percentage, :decimal, precision: 19, scale: 4, default: 0.0
    add_column :product_nature_categories, :financial_asset_depreciation_method, :string
    {
      # financial_asset_account_id: :financial_asset_account_id,
      financial_asset_depreciations_account_id: :financial_asset_allocation_account_id,
      financial_asset_depreciations_inputations_expenses_account_id: :financial_asset_expenses_account_id
    }.each do |o, n|
      rename_column :product_nature_categories, o, n
      add_index :product_nature_categories, n, name: "index_pnc_on_#{n}"
    end
    add_column :purchase_items, :fixed, :boolean, null: false, default: false

    # Adds forgotten indexes
    add_index :documents, :template_id
    add_index :imports, :importer_id
  end
end
