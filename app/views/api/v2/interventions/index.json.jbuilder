json.array! @interventions do |intervention|
  json.call(intervention, :id, :nature, :procedure_name, :number, :name, :started_at, :stopped_at, :description, :state, :working_duration, :request_intervention_id)
  json.costing intervention.costing.decorate.to_human_h
  json.parameters intervention.product_parameters do |parameter|
    json.partial! "/api/v2/intervention_product_parameters/show", parameter: parameter
  end
end
