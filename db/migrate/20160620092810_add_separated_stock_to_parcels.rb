class AddSeparatedStockToParcels < ActiveRecord::Migration[4.2]
  def change
    add_column :parcels, :separated_stock, :boolean
  end
end
