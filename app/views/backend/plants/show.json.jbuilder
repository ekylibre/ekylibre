json.partial! file: 'backend/products/show.json.jbuilder', resource: resource

last_sowing = Intervention.all.select { |int| int.procedure_name.to_sym == :sowing && int.outputs.map(&:product).include?(resource) }.last
sower = last_sowing && last_sowing.parameters.select { |eq| eq.reference_name.to_sym == :sower }.first
stop_at = last_sowing && last_sowing.stopped_at

json.application_width        Maybe(sower).product.application_width.value.to_f.or_else(nil)
json.application_width_unit   Maybe(sower).product.application_width.unit.or_else(nil)
json.rows_count               Maybe(sower).product.rows_count(at: stop_at).or_else(nil)
