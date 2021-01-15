class AddMissingFieldsOnPlantCountings < ActiveRecord::Migration[4.2]
  def change
    add_column :plant_countings, :number, :string
    add_column :plant_countings, :nature, :string
  end
end
