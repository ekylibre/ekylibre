json.extract! resource, :id, :name, :unit_name
json.identifiable true if resource.identifiable?
json.unitary true if resource.population_counting_unitary?
