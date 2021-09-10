class ChangeDataTypeToConditionning < ActiveRecord::Migration[5.0]
  def change
    if column_exists?(:purchase_items, :conditionning)
      change_column :purchase_items, :conditionning, :decimal
    end
  end
end
