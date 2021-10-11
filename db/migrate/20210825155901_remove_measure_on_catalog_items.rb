class RemoveMeasureOnCatalogItems < ActiveRecord::Migration[5.0]
  def change
    remove_column :catalog_items, :price_indicator_value, :decimal, precision: 19, scale: 4
    remove_column :catalog_items, :price_indicator_unit, :string
  end
end
