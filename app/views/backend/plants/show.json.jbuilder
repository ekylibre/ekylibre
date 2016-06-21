json.partial! file: 'backend/products/show.json.jbuilder', resource: resource

last_sowing = Intervention.all.select { |int| int.procedure_name.to_sym == :sowing && int.outputs.map(&:product).include?(resource) }.last
sower = last_sowing.parameters.select { |eq| eq.reference_name.to_sym == :sower }.first

json.application_width        sower.product.application_width.value.to_f
json.application_width_unit   sower.product.application_width.unit
json.rows_count               sower.product.rows_count(at: last_sowing.stopped_at)