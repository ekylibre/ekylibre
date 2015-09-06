json.extract! resource, :id, :name, :number, :work_number, :identification_number
variant = resource.variant
nature = variant.nature
json.unit_name variant.unit_name
json.variant_id resource.variant_id
json.nature_id resource.nature_id
json.category_id resource.category_id
json.population_counting nature.population_counting
json.born_at resource.born_at if resource.born_at
json.dead_at resource.dead_at if resource.dead_at
json.population resource.population
json.shape resource.shape.to_json if resource.shape
# Ownership
json.ownership do
  ownership = resource.current_ownership
  if ownership
    json.nature ownership.nature
    json.owner_id ownership.owner_id if ownership.owner
  else
    json.nature :none
  end
end
