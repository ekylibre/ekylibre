json.id role.id
json.label role.name
xml = Builder::XmlMarkup.new
json.permissions role.uses_permissions.to_xml root: 'uses-permissions', skip_types: true
