class AddMissingFieldsOnPlantCountings < ActiveRecord::Migration
  def change
    add_column :plant_countings, :number, :string
    add_column :plant_countings, :nature, :string
  end
end
