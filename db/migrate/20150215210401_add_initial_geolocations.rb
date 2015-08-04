class AddInitialGeolocations < ActiveRecord::Migration
  def change
    add_column :products, :initial_geolocation, :st_point, srid: 4326
  end
end
