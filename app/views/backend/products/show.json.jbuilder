json.extract! resource, :id, :name, :number, :work_number, :identification_number
variant = resource.variant
nature = variant.nature
json.unit_name variant.unit_name
json.conditioning_unit_name resource.conditioning_unit.name
json.conditioning_coefficient resource.conditioning_unit.coefficient
json.variant do
  json.id resource.variant_id
  json.name resource.variant_name
end
json.nature_id resource.nature_id
json.category_id resource.category_id
json.population_counting nature.population_counting
json.born_at resource.born_at if resource.born_at
json.dead_at resource.dead_at if resource.dead_at
json.population resource.population
json.shape resource.shape.to_json if resource.shape
json.netSurfaceAreaInHectare resource.net_surface_area.in(:hectare).value.to_f  if resource.shape
# Ownership
json.ownership do
  ownership = resource.current_ownership
  if ownership
    json.nature ownership.nature
    json.owner_id ownership.owner_id if ownership.owner
  else
    json.nature :none
  end
end

json.readings(resource.readings) do |reading|
  json.id(reading.id)
  json.indicator_name(reading.indicator_name)
  json.indicator_datatype(reading.indicator_datatype)
  json.absolute_measure_value_value(reading.absolute_measure_value_value)
  json.absolute_measure_value_unit(reading.absolute_measure_value_unit)
  json.boolean_value(reading.boolean_value)
  json.choice_value(reading.choice_value)
  json.decimal_value(reading.decimal_value)
  json.multi_polygon_value(reading.multi_polygon_value)
  json.integer_value(reading.integer_value)
  json.measure_value_value(reading.measure_value_value)
  json.measure_value_unit(reading.measure_value_unit)
  json.measure_value_unit_symbol(Onoma::Unit[reading.measure_value_unit]&.symbol)
  json.point_value(reading.point_value)
  json.string_value(reading.string_value)
end
# catalog price link to sale nature, variant / conditionning from shipment
if params[:sale_nature_id] && params[:planned_at]
  sale_nature = SaleNature.find_by_id(params[:sale_nature_id])
  if sale_nature && variant
    price_items = sale_nature.catalog.items.of_variant(variant).of_unit(resource.conditioning_unit).active_at(params[:planned_at])
    if price_items.any?
      json.default_sale_price price_items.first.pretax_amount
    end
  end
end
