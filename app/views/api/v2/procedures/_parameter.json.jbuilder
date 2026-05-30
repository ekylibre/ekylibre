json.name parameter.name
json.human_name parameter.human_name
json.type parameter.type
json.cardinality do
  json.minimum parameter.cardinality.minimum
  json.maximum parameter.cardinality.maximum
end
json.required parameter.required?

if parameter.is_a?(Procedo::Procedure::ProductParameter)
  json.filter parameter.filter
  json.variety parameter.variety
  json.derivative_of parameter.derivative_of
  json.default_name parameter.default_name
  if parameter.respond_to?(:handlers)
    # Procedo returns a Hash for parametrized handlers and an Array (often
    # empty) for parameters without handlers. Normalize to a list either way.
    handlers = parameter.handlers
    handler_list = handlers.is_a?(Hash) ? handlers.values : Array(handlers)
    # Expose each handler's details (name + indicator + unit) so API consumers
    # send a valid `quantity_handler` (e.g. "volume_area_density") rather than
    # guessing. `indicator`/`unit` are omitted for non-measure handlers such as
    # `population`.
    json.handlers handler_list do |handler|
      json.name handler.name
      json.indicator handler.indicator.name if handler.indicator
      json.unit handler.unit.name if handler.unit
    end
  end
elsif parameter.is_a?(Procedo::Procedure::GroupParameter)
  json.parameters parameter.parameters do |child|
    json.partial! 'api/v2/procedures/parameter', parameter: child
  end
end
