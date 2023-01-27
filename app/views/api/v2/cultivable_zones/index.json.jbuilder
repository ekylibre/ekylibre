json.array! @cultivable_zones do |cultivable_zone|
  json.call(cultivable_zone, :uuid, :work_number, :name, :shape, :shape_to_geojson)
end
