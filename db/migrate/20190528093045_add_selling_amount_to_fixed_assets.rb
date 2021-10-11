class AddSellingAmountToFixedAssets < ActiveRecord::Migration[4.2]
  def change
    add_column :fixed_assets, :selling_amount, :decimal, precision: 19, scale: 4
    add_column :fixed_assets, :pretax_selling_amount, :decimal, precision: 19, scale: 4
    add_reference :fixed_assets, :tax, index: true
  end
end
