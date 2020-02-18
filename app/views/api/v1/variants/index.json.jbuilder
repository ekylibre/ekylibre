json.array! variants do |variant|
  json.call(variant, :id, :name, :number, :variety, :derivative_of)

  json.nature_abilities variant.nature.abilities
end
