json.null! unless currency.present?
json.id currency.name
json.label currency.human_name
json.symbol currency.symbol
json.decimalSeparator '.'
json.thousandsSeparator ''
json.format nil
json.isMain (currency.name == Preference[:currency])
json.isActive currency.active

