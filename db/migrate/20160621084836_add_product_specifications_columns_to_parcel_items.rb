class AddProductSpecificationsColumnsToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :product_identification_number, :string
    add_column :parcel_items, :product_name, :string
    revert do
      add_reference :parcel_items, :product_shape_reading, index: true
      add_reference :parcel_items, :source_product_shape_reading, index: true
    end
  end
end
