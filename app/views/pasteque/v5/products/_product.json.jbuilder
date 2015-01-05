json.id product.id
json.reference product.reference rescue nil
json.barcode product.barcode rescue nil
json.label product.name
json.priceBuy nil
json.priceSell product.price rescue nil
json.visible true
json.scaled false
json.categoryId product.category_id
json.dispOrder nil
json.taxCatId product.tax.id rescue nil
json.attributeSetId nil
json.hasImage product.respond_to? :picture
json.discountEnabled false
json.discountRate 0.0
