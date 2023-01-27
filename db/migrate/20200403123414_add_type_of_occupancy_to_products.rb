class AddTypeOfOccupancyToProducts < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :type_of_occupancy, :string
  end
end
