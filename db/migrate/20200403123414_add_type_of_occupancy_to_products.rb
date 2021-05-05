class AddTypeOfOccupancyToProducts < ActiveRecord::Migration
  def change
    add_column :products, :type_of_occupancy, :string
  end
end
