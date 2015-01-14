class AddGeolocationToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :geolocation, :point, srid: 4326
  end
end
