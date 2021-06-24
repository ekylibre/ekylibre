class ChangeDataTypeToParcelItemStoringConditionningQuantity < ActiveRecord::Migration[5.0]
  def change
    change_column :parcel_item_storings, :conditionning_quantity, :decimal
  end
end
