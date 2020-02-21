json.call(product, :id, :name, :number, :population, :variety, :abilities, :born_at, :dead_at, :derivative_of, :france_maaid)

if product.container
  json.container_name product.container.name
end

if product.category.reference_name == "plant_medicine"
  json.france_maaid product.variant.france_maaid
end

json.variant_unit_name product.variant.unit_name

