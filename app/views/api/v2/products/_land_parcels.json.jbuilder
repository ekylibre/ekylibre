json.call(product, :id, :name, :net_surface_area, :born_at, :dead_at, :variety)

json.production_started_on product.production&.started_on
json.production_stopped_on product.production&.stopped_on
json.shape_svg product.initial_shape&.to_svg&.gsub!(/\"/, '\'')&.delete("\n")
