class UpdateLandParcelNetSurfaceArea < ActiveRecord::Migration
  def change
    LandParcel.find_each do |p|
      p.update_column(:reading_cache, {net_surface_area: p.calculate_net_surface_area})
    end
  end
end
