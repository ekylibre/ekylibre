class AddEquipmentToParcelItems < ActiveRecord::Migration
  def change
    unless column_exists? :parcel_items, :equipment_id
      add_column :parcel_items, :equipment_id, :integer
    end
  end
end
