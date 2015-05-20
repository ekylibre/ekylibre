json.locationId(stock.container ? stock.container.id.to_s : Product.first.id.to_s)
json.productId stock.variant_id.to_s
# json.attrSetInstId nil
json.qty stock.population.to_f
# json.security nil
# json.max nil
