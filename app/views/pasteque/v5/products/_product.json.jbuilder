json.id product.id
json.reference product.number
# json.barcode product.barcode
json.label product.name
# json.priceBuy nil
catalog_item = product.catalog_items.first
json.priceSell(catalog_item ? catalog_item.amount : 0.0)
json.visible true
json.scaled false
json.categoryId product.category_id.to_s
# json.dispOrder nil
taxations = product.category.sale_taxations
json.taxCatId (taxations.any? ? Nomen::Taxes.find(taxations.first.reference_name).nature : Tax.available_natures.first.name)
# json.attributeSetId nil
json.hasImage product.respond_to? :picture
json.discountEnabled false
json.discountRate 0.0
