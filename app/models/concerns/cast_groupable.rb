module CastGroupable
  extend ActiveSupport::Concern

  # Adds a cast or a cast_group to current cast_groupable
  def add_parameter!(parameter_name, *args, &block)
    fail 'No procedure' unless procedure
    attributes = args.extract_options!
    parameter = procedure.find!(parameter_name)
    if parameter.is_a?(Procedo::ProductParameter)
      add_product_parameter!(parameter_name, args.shift, attributes)
    elsif parameter.is_a?(Procedo::GroupParameter)
      add_group_parameter!(parameter_name, attributes, &block)
    else
      fail "Cannot add unknown parameter: #{parameter_name.inspect}"
    end
  end

  alias_method :add!, :add_parameter!

  # Add cast
  def add_product_parameter!(*args)
    fail 'No procedure' unless procedure
    attributes = args.extract_options!
    name = args.shift
    product = args.shift
    parameter = procedure.find!(name)
    attributes[:reference_name] = name
    attributes[:product] ||= product
    send(parameter.reflection_name).create!(attributes)
  end

  # Add cast group
  def add_group_parameter!(*args)
    fail 'No procedure' unless procedure
    attributes = args.extract_options!
    name = args.shift
    attributes[:reference_name] = name
    group = cast_groups.create!(attributes)
    yield group if block_given?
  end
end
