json.id catalog.id
json.label catalog.name
json.dispOrder nil
json.prices do
  json.array! catalog.items, partial: 'pasteque/v5/catalogs/price', as: :price
end
