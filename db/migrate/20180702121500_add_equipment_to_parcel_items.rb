class AddEquipmentToParcelItems < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :parcel_items, :equipment_id
      add_column :parcel_items, :equipment_id, :integer
    end
  end
end
