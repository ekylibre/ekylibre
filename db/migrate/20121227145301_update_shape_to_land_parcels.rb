class UpdateShapeToLandParcels < ActiveRecord::Migration
   def up
     remove_column :land_parcels, :shape
     add_column :land_parcels, :shape, :geometry
   end

   def down
     remove_column :land_parcels, :shape
     add_column :land_parcels, :shape, :geometry, :geographic => true
   end
end
