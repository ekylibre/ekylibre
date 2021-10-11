json.array! @interventions do |intervention|
  json.call(intervention, :id, :nature, :procedure_name, :number, :name, :started_at, :stopped_at, :description, :state, :working_duration, :request_intervention_id)
  json.costing intervention.costing.decorate.to_human_h
  json.parameters intervention.product_parameters do |parameter|
    json.id parameter.id
    json.role parameter.role
    json.name parameter.reference_name
    json.label parameter.reference.human_name
    json.product_id parameter.product_id
  end
end
