class CreateCviCultivableZones < ActiveRecord::Migration
  def change
    create_table :cvi_cultivable_zones do |t|
      t.string :name, null: false
      t.string :communes
      t.string :cadastral_references
      t.string :declared_area_unit
      t.decimal :declared_area_value, precision: 19, scale: 4
      t.string :formatted_declared_area
      t.string :calculated_area_unit
      t.string :formatted_calculated_area
      t.decimal :calculated_area_value, precision: 19, scale: 4
      t.string :land_parcels_status, default: :not_created
      t.geometry :shape, srid: 4326
      t.references :cvi_statement, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
