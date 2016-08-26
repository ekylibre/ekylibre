class AddSeparatedStockToParcels < ActiveRecord::Migration
  def change
    add_column :parcels, :separated_stock, :boolean
  end
end
