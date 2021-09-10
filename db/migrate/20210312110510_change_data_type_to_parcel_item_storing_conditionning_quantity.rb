class ChangeDataTypeToParcelItemStoringConditionningQuantity < ActiveRecord::Migration[5.0]
  def change
    if column_exists?(:parcel_item_storings, :conditionning_quantity)
      change_column :parcel_item_storings, :conditionning_quantity, :decimal
    end
  end
end
