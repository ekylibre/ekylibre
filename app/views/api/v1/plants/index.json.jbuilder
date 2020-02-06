json.array! @plants do |plant|
  json.call(plant, :id, :name, :number, :identification_number, :work_number, :born_at, :dead_at, :uuid, :variety, :derivative_of, :variant_id, :nature_id, :category_id, :activity_id)
end
