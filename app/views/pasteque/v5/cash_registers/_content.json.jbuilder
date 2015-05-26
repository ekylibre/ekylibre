json.id resource.id
json.label resource.name
json.locationId (resource.container ? resource.container.id : BuildingDivision.any? ? BuildingDivision.first.id : Building.any? ? Building.first.id : Product.first.id).to_s
json.nextTicketId resource.last_number || 0
