json.array! @resources do |resource|
  json.production_nature_id resource.production_nature_id
  json.production_system_name resource.production_system_name
  json.name resource.name
  json.average_yield resource.average_yield
  json.main resource.main
  json.analysis_items resource.analysis_items
end
