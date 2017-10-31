class AddEquipmentToPurchaseItems < ActiveRecord::Migration
  def change
    add_column :purchase_items, :equipment_id, :integer
  end
end
