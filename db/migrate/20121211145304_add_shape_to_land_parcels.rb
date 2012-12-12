class AddShapeToLandParcels < ActiveRecord::Migration
  def change
    add_column :land_parcels, :shape, :geometry, :geographic => true
  end
end
