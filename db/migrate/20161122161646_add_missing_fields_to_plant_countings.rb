class AddMissingFieldsToPlantCountings < ActiveRecord::Migration
  def change
    add_column :plant_countings, :working_width_value, :decimal, precision: 19, scale: 4
    add_column :plant_countings, :rows_count_value, :integer, precision: 19, scale: 4
  end
end
