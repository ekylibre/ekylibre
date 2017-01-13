class UpdatesZoomOptionsToMapBackgrounds < ActiveRecord::Migration
  def up
    execute("UPDATE map_backgrounds SET max_zoom=19 WHERE map_backgrounds.reference_name IN ('open_street_map.mapnik', 'open_street_map.hot', 'thunderforest.transport', 'thunderforest.transport_dark', 'open_map_surfer.roads', 'open_map_surfer.grayscale', 'esri.world_street_map', 'esri.world_topo_map', 'esri.world_imagery')")
    execute("UPDATE map_backgrounds SET max_zoom=18 WHERE map_backgrounds.reference_name IN ('open_street_map.black_and_white', 'open_street_map.de')")
  end
end
