class AddPlantCountings < ActiveRecord::Migration
  def change
    add_column :activities, :use_countings, :boolean, null: false, default: false

    create_table :plant_density_abaci do |t|
      t.string :name, null: false
      t.string :variety_name, null: false
      t.decimal :germination_percentage, precision: 19, scale: 4
      # in unit per surface. For example million_per_hectare
      t.string :seeding_density_unit, null: false
      t.string :sampling_length_unit, null: false
      t.stamps
      t.index :variety_name
      t.index :name, unique: true
    end

    create_table :plant_density_abacus_items do |t|
      t.references :plant_density_abacus, null: false, index: true
      t.decimal :seeding_density_value, precision: 19, scale: 4, null: false
      t.integer :plants_count, null: :false
      t.stamps
    end

    create_table :plant_countings do |t|
      t.references :plant, null: false, index: true
      t.references :plant_density_abacus, null: false, index: true
      t.references :plant_density_abacus_item, null: false, index: true
      t.decimal :average_value, precision: 19, scale: 4
      t.datetime :read_at
      t.text :comment
      t.stamps
    end

    create_table :plant_counting_items do |t|
      t.references :plant_counting, null: false, index: true
      t.integer :value, null: false
      t.stamps
    end
  end
end
