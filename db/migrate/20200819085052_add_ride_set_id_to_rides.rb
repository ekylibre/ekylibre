class AddRideSetIdToRides < ActiveRecord::Migration[4.2]
  def change
    add_reference :rides, :ride_set, index: true
    add_foreign_key :rides, :ride_sets
  end
end
