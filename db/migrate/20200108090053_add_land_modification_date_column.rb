class AddLandModificationDateColumn < ActiveRecord::Migration
  def change
    add_column :cvi_cadastral_plants, :land_modification_date , :date
    add_column :cvi_land_parcels, :land_modification_date , :date
    remove_column :cvi_land_parcels, :removed_at , :date
  end
end
