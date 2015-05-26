json.id resource.id
json.label resource.name
places = [] # resource.tables
json.places(places) do |place|
  json.id place.id
  json.label place.name
  json.x place.x
  json.y place.y
  json.floorId resource.id
end
json.hasImage resource.picture_file_name.present?
