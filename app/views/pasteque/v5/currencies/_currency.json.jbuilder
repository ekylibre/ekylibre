currency = Nomen::Currencies[currency]
json.null! unless currency.present?
json.id currency.number
json.label currency.name
json.symbol currency.symbol
json.decimalSeparator nil
json.thousandsSeparator nil
json.format nil
json.isMain (currency.name == Preference[:currency])
json.isActive currency.active

