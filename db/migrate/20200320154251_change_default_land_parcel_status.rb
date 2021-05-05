class ChangeDefaultLandParcelStatus < ActiveRecord::Migration
  def up
    change_column_default :cvi_cultivable_zones, :land_parcels_status, :not_started 
  end

  def down
    change_column_default :cvi_cultivable_zones, :land_parcels_status, :not_created
  end
end
