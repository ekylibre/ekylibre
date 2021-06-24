class CreateCviStatements < ActiveRecord::Migration
  def change
    create_table :cvi_statements do |t|
      t.string :cvi_number, null: false
      t.date :extraction_date, null: false
      t.string :siret_number, null: false
      t.string :farm_name, null: false
      t.string :declarant, null: false
      t.decimal :total_area_value, precision: 19, scale: 4
      t.string :total_area_unit
      t.integer :cadastral_plant_count, default: 0
      t.integer :cadastral_sub_plant_count, default: 0
      t.string :state, null: false

      t.timestamps null: false
    end
  end
end
