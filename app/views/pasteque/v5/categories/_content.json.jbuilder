json.id resource.id.to_s
# json.parent_id nil # See Android app
# json.parentId nil
json.label resource.name
json.hasImage resource.respond_to? :picture
json.dispOrder 0
