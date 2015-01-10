json.id attribute.id
json.label attribute.name
json.values do
  json.array! attribute.values, partial: 'pasteque/v5/attributes/attribute_value', as: :attribute_value
end
json.dispOrder nil
