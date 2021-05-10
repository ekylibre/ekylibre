class ChangeDataTypeToConditionning < ActiveRecord::Migration[5.0]
  def change
    change_column :purchase_items, :conditionning, :decimal
  end
end
