json.id floor.id
json.label floor.name
json.places(floor.tables) do |place|
  json.id place.id
  json.label place.name
  json.x place.x
  json.y place.y
  json.floorId floor.id
end
json.hasImage floor.picture_file_name.present?
