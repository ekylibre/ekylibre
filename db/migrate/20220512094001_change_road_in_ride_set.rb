class ChangeRoadInRideSet < ActiveRecord::Migration[5.0]
  def change
    change_column :ride_sets, :road, :decimal, precision: 19, scale: 4
  end
end
