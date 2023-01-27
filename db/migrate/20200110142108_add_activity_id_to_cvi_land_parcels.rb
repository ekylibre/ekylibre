class AddActivityIdToCviLandParcels < ActiveRecord::Migration[4.2]
  def change
    add_reference :cvi_land_parcels, :activity, index: true, foreign_key: true
  end
end
