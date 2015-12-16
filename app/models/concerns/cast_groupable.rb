module CastGroupable
  extend ActiveSupport::Concern

  # Adds a cast or a cast_group to current cast_groupable
  def add_item!(item_name, *args, &block)
    fail 'No procedure' unless procedure
    attributes = args.extract_options!
    item = procedure.find!(item_name)
    if item.is_a?(Procedo::Parameter)
      add_cast!(item_name, args.shift, attributes)
    elsif item.is_a?(Procedo::ParameterGroup)
      add_cast_group!(item_name, attributes, &block)
    else
      fail "Cannot add unknown item: #{item_name.inspect}"
    end
  end

  alias_method :add!, :add_item!

  # Add cast
  def add_cast!(*args)
    fail 'No procedure' unless procedure
    attributes = args.extract_options!
    name = args.shift
    product = args.shift
    item = procedure.find!(name)
    attributes[:parameter_name] = name
    if item.input?
      attributes[:source_product] ||= product
    else
      attributes[:product] ||= product
    end
    send(item.reflection_name).create!(attributes)
  end

  # Add cast group
  def add_cast_group!(*args)
    fail 'No procedure' unless procedure
    attributes = args.extract_options!
    name = args.shift
    attributes[:parameter_group_name] = name
    group = cast_groups.create!(attributes)
    yield group if block_given?
  end

end
