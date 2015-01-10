json.id tariff_area.id
json.label tariff_area.name
json.dispOrder nil
json.prices do
  json.array! tariff_area.items, partial: 'pasteque/v5/tariff_areas/price', as: :price
end
