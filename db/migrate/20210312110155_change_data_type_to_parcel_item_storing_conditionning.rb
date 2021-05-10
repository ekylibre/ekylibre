class ChangeDataTypeToParcelItemStoringConditionning < ActiveRecord::Migration[5.0]
  def change
    change_column :parcel_item_storings, :conditionning, :decimal
  end
end
