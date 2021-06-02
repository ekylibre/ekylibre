class CreateCviLandParcels < ActiveRecord::Migration
  def change
    create_table :cvi_land_parcels do |t|
      t.string :name, null: false
      t.string :commune
      t.string :locality
      t.integer :designation_of_origin_id
      t.string :vine_variety_id
      t.string :calculated_area_unit
      t.decimal :calculated_area_value, precision: 19, scale: 5
      t.string :declared_area_unit
      t.decimal :declared_area_value, precision: 19, scale: 5
      t.geometry :shape, srid: 4326
      t.references :campaign, index: true, foreign_key: true
      t.string :rootstock_id
      t.decimal :inter_vine_plant_distance_value, precision: 19, scale: 4
      t.string :inter_vine_plant_distance_unit
      t.decimal :inter_row_distance_value, precision: 19, scale: 4
      t.string :inter_row_distance_unit
      t.string :state
      t.references :cvi_cultivable_zone, index: true, foreign_key: true
      t.date :removed_at

      t.timestamps null: false
    end
  end
end
