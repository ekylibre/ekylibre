json.call(product, :id, :name, :number, :variety, :abilities, :born_at, :dead_at, :derivative_of, :population)

json.unit_name product.conditioning_unit.present? ? product.conditioning_unit.name : product.variant.unit_name

json.container_name product.container.present? ? product.container.name : ""

if product.category.reference_name == "plant_medicine"
  json.france_maaid product.variant.france_maaid
end
