json.ignore_nil!
json.array! products do |product|
  json.partial! product.model_name.route_key.to_s, locals: { product: product }
end
