json.call(product, :id, :name, :net_surface_area, :variety, :activity_id, :activity_name, :born_at, :dead_at, :abilities, :work_number)

json.production_started_on product.production.started_on
json.production_stopped_on product.production.stopped_on
