json.array! @interventions do |intervention|
  json.call(intervention, :id, :nature, :procedure_name, :number, :name, :started_at, :stopped_at, :description)
  json.parameters intervention.product_parameters do |parameter|
    json.id parameter.id
    json.role parameter.role
    json.name parameter.reference_name
    json.label parameter.reference.human_name

    if parameter.product
      json.product do
        json.id parameter.product_id
        json.name parameter.product_name

        if parameter.reference_name == "plant_medicine"
          json.usage_id parameter.usage_id
          json.allowed_entry_factor parameter.allowed_entry_factor
          json.allowed_harvest_factor parameter.allowed_harvest_factor
        end
      end
    end
  end
end
