json.id attribute.id
json.label attribute.name
json.values do
  json.array! attribute.values, partial: 'value', as: :value
end
json.dispOrder nil
