class AddShapeToLandParcels < ActiveRecord::Migration
  def change
    add_column :land_parcels, :shape, :geography
  end
end
