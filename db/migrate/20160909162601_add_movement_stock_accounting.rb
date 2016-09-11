class AddMovementStockAccounting < ActiveRecord::Migration
  def change
    add_reference :product_nature_categories, :movement_stock_account, index: true
  end
end
