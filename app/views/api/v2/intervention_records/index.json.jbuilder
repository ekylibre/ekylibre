json.set! :pagination do
  json.call(@pagination, :elements, :page, :per_page, :total_elements, :page_count)
end

json.set! :data do
  json.array! @interventions do |intervention|
    json.call(intervention, :id, :number, :name, :procedure_name, :started_at, :stopped_at, :working_duration, :state, :description)
    provider = intervention.provider.presence&.with_indifferent_access
    json.provider provider ? provider.slice(:vendor, :name, :id) : nil

    json.targets intervention.targets do |target|
      json.partial! 'parameter', parameter: target
      json.activity_production_id target.product&.activity_production_id
      json.working_zone_area_value target.working_zone_area_value&.to_f
      json.working_zone_area_unit InterventionProductParameter::DEFAULT_WORKING_ZONE_AREA_UNIT if target.working_zone_area_value
    end

    json.inputs intervention.inputs do |input|
      json.partial! 'parameter', parameter: input
      json.variant_id input.variant_id
      json.variant_name input.variant&.name
      json.quantity_value input.quantity_value&.to_f
      json.quantity_population input.quantity_population&.to_f
      json.quantity_handler input.quantity_handler
      json.quantity_unit_name input.quantity_unit_name
      json.quantity_indicator_name input.quantity_indicator_name
    end

    json.tools intervention.tools do |tool|
      json.partial! 'parameter', parameter: tool
    end

    json.doers intervention.doers do |doer|
      json.partial! 'parameter', parameter: doer
    end
  end
end
