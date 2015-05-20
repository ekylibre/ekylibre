json.id cash_register.id
json.label cash_register.name
json.locationId (cash_register.container ? cash_register.container.id : BuildingDivision.any? ? BuildingDivision.first.id : Building.any? ? Building.first.id : Product.first.id).to_s
json.nextTicketId cash_register.last_number || 0
