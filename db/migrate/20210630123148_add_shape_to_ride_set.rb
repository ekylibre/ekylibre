class AddShapeToRideSet < ActiveRecord::Migration[5.0]
  def change
    add_column :ride_sets, :shape, :geometry, srid: 4326
  end
end
