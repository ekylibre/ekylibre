json.ignore_nil!
json.array! products do |product|
  json.partial! "#{product.model_name.route_key}", locals: { product: product }
end
