class AddEquipmentToPurchaseItems < ActiveRecord::Migration
  def change
    unless column_exists? :purchase_items, :equipment_id
      add_column :purchase_items, :equipment_id, :integer
    end
  end
end
