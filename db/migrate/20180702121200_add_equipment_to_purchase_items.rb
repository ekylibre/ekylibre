class AddEquipmentToPurchaseItems < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :purchase_items, :equipment_id
      add_column :purchase_items, :equipment_id, :integer
    end
  end
end
