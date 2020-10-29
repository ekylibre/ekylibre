class AddFixedAssetToSaleItems < ActiveRecord::Migration
  def change
    add_column :sale_items, :fixed, :boolean, null: false, default: false
    add_column :sale_items, :preexisting_asset, :boolean
    add_column :sale_items, :depreciable_product_id, :integer, index: true
    add_foreign_key :sale_items, :products, column: :depreciable_product_id
    add_reference :sale_items, :fixed_asset, index: true
  end
end
