class DeleteRootstockReferencesFromCviLandParcel < ActiveRecord::Migration[4.2]
  def change
    remove_column :cvi_land_parcels, :rootstock_id, :string
  end
end
