# Add domain type to read spatial type
YAML.add_domain_type("wgs84.geo.ekylibre.org,2014", "multipolygon") do |type, val|
  Charta::Geometry.new({type: "MultiPolygon", coordinates: val}.stringify_keys, :WGS84).to_ewkt
end
