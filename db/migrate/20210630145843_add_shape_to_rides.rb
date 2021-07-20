class AddShapeToRides < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :shape, :geometry, srid: 4326
  end
end
