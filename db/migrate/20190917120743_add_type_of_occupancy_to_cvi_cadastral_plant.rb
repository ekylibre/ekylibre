class AddTypeOfOccupancyToCviCadastralPlant < ActiveRecord::Migration
  def change
    add_column :cvi_cadastral_plants, :type_of_occupancy, :string
  end
end
