class AddMergeStockToParcelItem < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :merge_stock, :boolean, default: true
  end
end
