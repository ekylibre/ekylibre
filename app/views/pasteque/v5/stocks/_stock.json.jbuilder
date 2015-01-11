json.locationId stock.default_storage.id rescue nil
json.productId stock.variant_id
json.attrSetInstId nil
json.qty stock.contents.count
json.security stock.security_level rescue nil
json.max stock.max rescue nil
