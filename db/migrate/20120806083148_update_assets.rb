class UpdateAssets < ActiveRecord::Migration
  def up
    rename_column :assets, :deprecated_amount, :depreciated_amount
    add_column :assets, :current_amount, :decimal, :precision=>19, :scale=>4
    change_column_null :assets, :purchase_amount, true
    change_column_null :assets, :purchased_on, true
    change_column :assets,  :purchase_amount, :decimal, :precision=>19, :scale=>4
    change_column :assets,  :depreciable_amount, :decimal, :precision=>19, :scale=>4
    change_column :assets,  :depreciated_amount, :decimal, :precision=>19, :scale=>4
    change_column :asset_depreciations, :amount, :decimal, :precision=>19, :scale=>4
    add_column :asset_depreciations, :protected, :boolean, :null => false, :default => false
    add_column :asset_depreciations, :financial_year_id, :integer
  end

  def down
    remove_column :asset_depreciations, :financial_year_id
    remove_column :asset_depreciations, :protected
    rename_column :assets, :depreciated_amount, :deprecated_amount
  end
end
