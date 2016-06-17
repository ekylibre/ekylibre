class AddProductSpecificationsColumnsToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :identification_number, :string
    add_column :parcel_items, :name, :string
  end
end
