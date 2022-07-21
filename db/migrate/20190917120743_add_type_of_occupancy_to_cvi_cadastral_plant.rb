class AddTypeOfOccupancyToCviCadastralPlant < ActiveRecord::Migration[4.2]
  def change
    add_column :cvi_cadastral_plants, :type_of_occupancy, :string
  end
end
