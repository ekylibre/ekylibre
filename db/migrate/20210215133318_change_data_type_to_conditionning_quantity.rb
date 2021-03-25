class ChangeDataTypeToConditionningQuantity < ActiveRecord::Migration[5.0]
  def change
    change_column :purchase_items, :conditionning_quantity, :decimal
  end
end
