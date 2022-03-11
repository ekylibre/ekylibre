class AddCatalogItemUpdateToSaleItem < ActiveRecord::Migration[5.0]
  def change
    add_column :sale_items, :catalog_item_update, :boolean, default: false
  end
end
