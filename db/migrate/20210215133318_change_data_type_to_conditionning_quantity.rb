class ChangeDataTypeToConditionningQuantity < ActiveRecord::Migration[5.0]
  def change
    if column_exists?(:purchase_items, :conditionning_quantity)
      change_column :purchase_items, :conditionning_quantity, :decimal
    end
  end
end
