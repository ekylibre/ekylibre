json.id attribute_set.id
json.label attribute_set.name
json.attributes do
  json.array! attribute_set.attributes, partial: 'pasteque/v5/attributes/attribute', as: :attribute
end
