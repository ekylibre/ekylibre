# Please update app/helpers/backend/form_builder.rb #variant_quantifier_of method
# if you change something here
# TODO Dry it
json.array! @product_nature_variant.unified_quantifiers(params.slice(:population, :working_duration)) do |quantifier|
  json.label :unit_and_indicator.tl(indicator: quantifier[:indicator][:human_name], unit: quantifier[:unit][:human_name])
  json.indicator quantifier[:indicator][:name]
  json.unit quantifier[:unit][:name]
  json.unit_symbol quantifier[:unit][:symbol]
end
