class RemoveDefaultValueFromSaleItemsQuantity < ActiveRecord::Migration
  def change
    change_column_default :sale_items, :quantity, nil
  end
end
