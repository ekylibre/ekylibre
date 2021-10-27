class ChangeMergeStockDefaultValueToParcelItem < ActiveRecord::Migration[5.0]
  def change
    change_column_default :parcel_items, :merge_stock, false
  end
end
