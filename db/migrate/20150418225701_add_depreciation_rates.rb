class AddDepreciationRates < ActiveRecord::Migration

  def change
    add_column :product_nature_categories, :depreciation_rate, :decimal, precision: 19, scale: 4, default: 0.0
    add_column :purchase_items, :depreciation, :boolean, null: false, default: false
  end

end
