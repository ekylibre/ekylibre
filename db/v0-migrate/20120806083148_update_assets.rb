class UpdateAssets < ActiveRecord::Migration
  def up
    rename_column :assets, :deprecated_amount, :depreciated_amount
    rename_column :assets, :account_id, :allocation_account_id
    add_column :assets, :current_amount, :decimal, :precision=>19, :scale=>4
    add_column :assets, :charges_account_id, :integer
    change_column_null :assets, :purchase_amount, true
    change_column_null :assets, :purchased_on, true
    change_column :assets,  :purchase_amount, :decimal, :precision=>19, :scale=>4
    change_column :assets,  :depreciable_amount, :decimal, :precision=>19, :scale=>4
    change_column :assets,  :depreciated_amount, :decimal, :precision=>19, :scale=>4
    add_column :assets, :depreciation_percentage, :decimal, :precision=>19, :scale=>4

    change_column :asset_depreciations, :amount, :decimal, :precision=>19, :scale=>4
    add_column :asset_depreciations, :protected, :boolean, :null => false, :default => false
    add_column :asset_depreciations, :financial_year_id, :integer
    add_column :asset_depreciations, :asset_amount, :decimal, :precision=>19, :scale=>4
    add_column :asset_depreciations, :depreciated_amount, :decimal, :precision=>19, :scale=>4

    add_column :financial_years, :last_journal_entry_id, :integer
  end

  def down
    remove_column :financial_years, :last_journal_entry_id

    remove_column :asset_depreciations, :depreciated_amount
    remove_column :asset_depreciations, :asset_amount
    remove_column :asset_depreciations, :financial_year_id
    remove_column :asset_depreciations, :protected
    
    remove_column :assets, :depreciation_percentage
    remove_column :assets, :charges_account_id
    remove_column :assets, :current_amount
    rename_column :assets, :allocation_account_id, :account_id
    rename_column :assets, :depreciated_amount, :deprecated_amount
  end
end
