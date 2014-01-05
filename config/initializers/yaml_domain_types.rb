# Add domain type to read spatial type
YAML.add_domain_type("ekylibre.org,2014", "multipolygon") do |type, val| 
  RGeo::Geographic.spherical_factory(srid: 4326).parse_wkt(val)
end
