class ChangeDataTypeToParcelItemStoringConditionning < ActiveRecord::Migration[5.0]
  def change
    if column_exists?(:parcel_item_storings, :conditionning)
      change_column :parcel_item_storings, :conditionning, :decimal
    end
  end
end
