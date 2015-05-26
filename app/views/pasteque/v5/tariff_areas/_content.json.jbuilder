json.id resource.id
json.label resource.name
json.dispOrder resource.id
json.prices do
  json.array! resource.items, partial: 'price', as: :price
end
