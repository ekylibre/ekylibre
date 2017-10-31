class AddEquipmentToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :equipment_id, :integer
  end
end
