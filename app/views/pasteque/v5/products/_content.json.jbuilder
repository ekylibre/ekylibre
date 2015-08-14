json.id resource.id
json.reference resource.number
# json.barcode resource.barcode
json.label resource.name
# json.priceBuy nil
catalog_item = resource.catalog_items.first
json.priceSell(catalog_item ? catalog_item.amount : 0.0)
json.visible true
json.scaled false
json.categoryId resource.category_id.to_s
# json.dispOrder nil
taxations = resource.category.sale_taxations
json.taxCatId (taxations.any? ? Nomen::Tax.find(taxations.first.reference_name).nature : Tax.available_natures.first.name)
# json.attributeSetId nil
json.hasImage resource.respond_to? :picture
json.discountEnabled false
json.discountRate 0.0
