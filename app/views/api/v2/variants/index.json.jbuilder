json.array! variants do |variant|
  json.call(variant, :id, :name, :number, :variety, :derivative_of, :reference_name)
  json.unit variant.default_unit_name
  json.nature_abilities variant.nature.abilities
end
