json.locationId(resource.container ? resource.container.id.to_s : Product.first.id.to_s)
json.productId resource.variant_id.to_s
# json.attrSetInstId nil
json.qty resource.population.to_f
# json.security nil
# json.max nil
