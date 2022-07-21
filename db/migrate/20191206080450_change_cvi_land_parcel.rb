class ChangeCviLandParcel < ActiveRecord::Migration[4.2]
  def change
    remove_column :cvi_land_parcels, :commune, :string
    remove_column :cvi_land_parcels, :locality, :string
    remove_reference :cvi_land_parcels, :campaign, index: true, foreign_key: true
    add_column :cvi_land_parcels, :planting_campaign, :string
  end
end