class AddProductSpecificationsColumnsToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :product_identification_number, :string
    add_column :parcel_items, :product_name, :string
  end
end
