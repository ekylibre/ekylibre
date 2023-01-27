class RemoveDefaultValueFromSaleItemsQuantity < ActiveRecord::Migration[4.2]
  def change
    change_column_default :sale_items, :quantity, nil
  end
end
