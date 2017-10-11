class ChangeQuantityDefaultValueInPurchaseItems < ActiveRecord::Migration
  def up
  	change_column_default :purchase_items, :quantity, 0.0
  end

  def down
		change_column_default :purchase_items, :quantity, 1.0
  end
end
