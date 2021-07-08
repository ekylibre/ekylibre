json.array! plants do |plant|
  json.call(plant, :id, :name, :net_surface_area, :variety, :activity_id, :activity_name)

  json.production_started_on plant.production.started_on
  json.production_stopped_on plant.production.stopped_on
end
