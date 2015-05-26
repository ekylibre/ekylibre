json.id attribute_set.id
json.label attribute_set.name
json.attributes do
  json.array! attribute_set.attributes, partial: 'attribute', as: :attribute
end
