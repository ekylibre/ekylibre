json.id resource.id
json.label resource.name
places = [] # resource.tables
json.places(places) do |place|
  json.id place.id
  json.label place.name
  # Emulate place position in 4-column layout
  json.x place.id % 4
  json.y place.id / 4
  json.floorId resource.id
end
json.hasImage resource.picture_file_name.present?
