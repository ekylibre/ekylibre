class AddWaitingBookkeepOnFixedAssets < ActiveRecord::Migration
  def change
    add_column :fixed_assets, :waiting_on, :date
    add_column :fixed_assets, :waiting_journal_entry_id, :integer
    add_column :fixed_assets, :waiting_asset_account_id, :integer
    add_column :fixed_assets, :special_imputation_asset_account_id, :integer
  end
end
