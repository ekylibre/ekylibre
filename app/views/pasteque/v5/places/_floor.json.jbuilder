json.id floor.id
json.label floor.name
json.places do |place.places|
  json.id place.id
  json.label place.name
  json.x (1..4).to_a.sample
  json.y (place.id).to_a.sample
  json.floorId floor.id
end
json.hasImage floor.picture_file_name.present?
