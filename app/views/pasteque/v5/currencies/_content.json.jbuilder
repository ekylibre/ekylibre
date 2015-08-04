json.null! unless resource.present?
json.id resource.name
json.label resource.human_name
json.symbol resource.symbol
json.decimalSeparator '.'
json.thousandsSeparator ''
json.format nil
json.isMain (resource.name == Preference[:currency])
json.isActive resource.active
