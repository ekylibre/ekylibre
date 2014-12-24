class NormalizeFinancialsAssets < ActiveRecord::Migration
  def change
    # in product_nature_categories
    add_column :product_nature_categories, :financial_asset_depreciations_account_id, :integer
    add_column :product_nature_categories, :financial_asset_depreciations_inputations_expenses_account_id, :integer
  end
end
