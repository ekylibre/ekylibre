json.extract! resource, :id, :name, :unit_name
json.unitary true if resource.population_counting_unitary?