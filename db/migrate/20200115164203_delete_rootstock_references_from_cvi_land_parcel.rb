class DeleteRootstockReferencesFromCviLandParcel < ActiveRecord::Migration
  def change
    remove_column :cvi_land_parcels, :rootstock_id, :string
  end
end
