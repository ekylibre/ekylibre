class AddProductInCatalogItem < ActiveRecord::Migration[5.0]
  def change
    add_reference :catalog_items, :product, index: true, foreign_key: { to_table: :products }
  end
end
