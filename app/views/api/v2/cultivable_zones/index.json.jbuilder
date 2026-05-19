json.array! @cultivable_zones do |cultivable_zone|
  json.call(cultivable_zone, :id, :uuid, :work_number, :name, :shape, :shape_to_geojson)
end
