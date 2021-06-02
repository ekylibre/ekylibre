class CreateCviCadastralPlants < ActiveRecord::Migration
  def change
    create_table :cvi_cadastral_plants do |t|
      t.string :commune, null: false
      t.string :locality
      t.string :insee_number, null: false
      t.string :section, null: false
      t.string :work_number, null: false
      t.string :land_parcel_number
      t.integer :designation_of_origin_id
      t.string :vine_variety_id
      t.decimal :area_value, precision: 19, scale: 4
      t.string :area_unit
      t.string :campaign, null: false
      t.string :rootstock_id
      t.decimal :inter_vine_plant_distance_value, precision: 19, scale: 4
      t.string :inter_vine_plant_distance_unit
      t.decimal :inter_row_distance_value, precision: 19, scale: 4
      t.string :inter_row_distance_unit
      t.string :state, null: false
      t.references :cvi_statement, index: true, foreign_key: true
      t.string :land_parcel_id

      t.timestamps null: false
    end
  end
end
