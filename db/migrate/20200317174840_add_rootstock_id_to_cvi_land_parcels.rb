class AddRootstockIdToCviLandParcels < ActiveRecord::Migration[4.2]
  def change
    add_column :cvi_land_parcels, :rootstock_id, :string
  end
end
