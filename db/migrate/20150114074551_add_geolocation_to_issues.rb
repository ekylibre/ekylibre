class AddGeolocationToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :geolocation, :st_point, srid: 4326
  end
end
