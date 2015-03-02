# Please update app/helpers/backend/form_builder.rb #variant_quantifier_of method
# if you change something here
# TODO Dry it
json.array! @product_nature_variant.quantifiers do |pair|
  indicator, unit = pair.first, pair.second
  json.label :unit_and_indicator.tl(indicator: indicator.human_name, unit: unit.human_name)
  json.indicator indicator.name
  json.unit unit.name
  json.unit_symbol unit.symbol
end
