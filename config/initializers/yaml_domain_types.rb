# Add domain type to read spatial type
YAML.add_domain_type("wgs84.geo.ekylibre.org,2014", "multipolygon") do |type, val|
  Charta::Geometry.new({type: "MultiPolygon", coordinates: val}.stringify_keys, :WGS84).to_ewkt
end

YAML.add_domain_type("wgs84.geo.ekylibre.org,2014", "polygon") do |type, val|
  Charta::Geometry.new({type: "Polygon", coordinates: val}.stringify_keys, :WGS84).to_ewkt
end

YAML.add_domain_type("wgs84.geo.ekylibre.org,2014", "linestring") do |type, val|
  Charta::Geometry.new({type: "LineString", coordinates: val}.stringify_keys, :WGS84).to_ewkt
end

YAML.add_domain_type("wgs84.geo.ekylibre.org,2014", "point") do |type, val|
  Charta::Geometry.new({type: "Point", coordinates: val}.stringify_keys, :WGS84).to_ewkt
end
