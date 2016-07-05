json.extract! resource, :id, :name, :unit_name
json.identifiable true if resource.identifiable?
