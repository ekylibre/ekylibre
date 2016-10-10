json.partial! file: 'backend/products/show.json.jbuilder', resource: resource

last_sowing = Intervention.real.where(procedure_name: :sowing, id: InterventionOutput.where(product: resource).select(:intervention_id)).order(started_at: :desc).first
sower = last_sowing && last_sowing.parameters.select { |eq| eq.reference_name.to_sym == :sower }.first
stop_at = last_sowing && last_sowing.stopped_at

json.application_width        Maybe(sower).product.variant.application_width.value.to_f.or_else(nil)
json.application_width_unit   Maybe(sower).product.variant.application_width.unit.or_else(nil)
json.rows_count               Maybe(sower).product.variant.rows_count(at: stop_at).or_else(nil)
