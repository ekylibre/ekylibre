json.partial! file: 'backend/products/show.json.jbuilder', resource: resource

if sower
  variant = resource.sower.product.variant

  json.application_width        variant.application_width.value.to_f
  json.application_width_unit   variant.application_width.unit
  json.rows_count               variant.rows_count(at: last_sowing && last_sowing.stopped_at)
end