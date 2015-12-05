# Add domain type to read spatial type
YAML.add_domain_type('wgs84.geo.ekylibre.org,2014', 'multipolygon') do |_type, val|
  Charta.new_geometry({ type: 'MultiPolygon', coordinates: val }.stringify_keys, :WGS84).to_ewkt
end

YAML.add_domain_type('wgs84.geo.ekylibre.org,2014', 'polygon') do |_type, val|
  Charta.new_geometry({ type: 'Polygon', coordinates: val }.stringify_keys, :WGS84).to_ewkt
end

YAML.add_domain_type('wgs84.geo.ekylibre.org,2014', 'linestring') do |_type, val|
  Charta.new_geometry({ type: 'LineString', coordinates: val }.stringify_keys, :WGS84).to_ewkt
end

YAML.add_domain_type('wgs84.geo.ekylibre.org,2014', 'point') do |_type, val|
  Charta.new_geometry({ type: 'Point', coordinates: val }.stringify_keys, :WGS84).to_ewkt
end

# YAML.add_domain_type("wgs84.geo.ekylibre.org,2015", "wkt") do |type, val|
#   Charta.new_geometry(val, :WGS84)
# end
