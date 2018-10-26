class ChangeParcelItemStoringQuantityType < ActiveRecord::Migration
  def change
    change_column :parcel_item_storings, :quantity, :decimal, precision: 19, scale: 4
  end
end
