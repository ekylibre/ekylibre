class AddRootstockIdToCviLandParcels < ActiveRecord::Migration
  def change
    add_column :cvi_land_parcels, :rootstock_id, :string
  end
end
