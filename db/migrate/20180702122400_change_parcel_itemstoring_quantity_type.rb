class ChangeParcelItemstoringQuantityType < ActiveRecord::Migration[4.2]
  def change
    change_column :parcel_item_storings, :quantity, :decimal, precision: 19, scale: 4
  end
end
