class AddActivityIdToCviLandParcels < ActiveRecord::Migration
  def change
    add_reference :cvi_land_parcels, :activity, index: true, foreign_key: true
  end
end
