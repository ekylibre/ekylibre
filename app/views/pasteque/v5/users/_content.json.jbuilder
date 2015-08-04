json.id resource.id.to_s
json.name resource.full_name
# json.password resource.encrypted_password
# We simulate use of personal role
json.roleId resource.id.to_s
json.visible !resource.locked
json.hasImage resource.picture.present?
json.card '9876543210'
