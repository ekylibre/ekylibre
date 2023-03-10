class RemoveEquipmentNameFromRides < ActiveRecord::Migration[5.1]
  def change
    remove_column :rides, :equipment_name, :string
  end
end
