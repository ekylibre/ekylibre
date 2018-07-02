class ChangeQuantityDefaultValueInPurchaseItems < ActiveRecord::Migration
  def up
    change_column_default :purchase_items, :quantity, nil
  end

  def down
    change_column_default :purchase_items, :quantity, 1.0
  end
end
