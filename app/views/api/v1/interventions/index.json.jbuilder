json.array! @interventions do |intervention|
  json.call(intervention, :id, :procedure_name, :number, :name, :started_at, :stopped_at, :description)
  json.parameters intervention.product_parameters, :id, :role, :reference_name, :human_reference_name do |parameter|
    if parameter.product
      json.product do
        json.id parameter.product_id
        json.name parameter.product_name
      end
    end
  end
end
