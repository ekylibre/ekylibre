class AddMergeStockToParcelItem < ActiveRecord::Migration
  def change
    add_column :parcel_items, :merge_stock, :boolean, default: true
  end
end
