module CastGroupable
  extend ActiveSupport::Concern

  # Adds a cast or a cast_group to current cast_groupable
  def add!(*args)
    fail "No procedure" unless procedure
    attributes = args.extract_options!
    item_name = [args.shift, attributes.delete(:parameter_name), attributes.delete(:parameter_group_name)].detect(&:present?)
    item = procedure.find(item_name)
    unless item
      fail "No item found for: #{item_name.inspect}"
    end
    if item.is_a?(Procedo::Parameter)
      attributes[:parameter_name] = item.name
      if item.input?
        attributes[:source_product] ||= args.shift
      else
        attributes[:product] ||= args.shift
      end
      send(item.reflection_name).create!(attributes)      
    elsif item.is_a?(Procedo::ParameterGroup)
      attributes[:parameter_group_name] = item.name
      group = cast_groups.create!(attributes)
      yield group if block_given?
    else
      fail "What ???"
    end
  end

  
end
