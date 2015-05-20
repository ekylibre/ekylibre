json.id user.id.to_s
json.name user.full_name
# json.password user.encrypted_password
json.roleId user.role_id.to_s
json.visible !user.locked
json.hasImage user.picture.present?
json.card "9876543210"

