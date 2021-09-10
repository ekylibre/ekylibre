class AddMeasureOnCatalogItems < ActiveRecord::Migration[4.2]
  def change
    add_column :catalog_items, :price_indicator_value, :decimal, precision: 19, scale: 4
    add_column :catalog_items, :price_indicator_unit, :string
  end
end
