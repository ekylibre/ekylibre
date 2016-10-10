module Indicateable
  extend ActiveSupport::Concern

  included do
    has_many :readings, class_name: 'ProductReading', dependent: :destroy, inverse_of: :product

    scope :with_given_readings, lambda { |indicator_name|
      where(id: ProductReading.where(indicator_name: indicator_name))
    }

    scope :indicate, lambda { |indicator_values, options = {}|
      read_at = options[:at] || Time.zone.now
      ids = []
      # TODO: Build conditions to filter on indicator_values
      indicator_values.each do |name, value|
        data = ProductReading.of_products(self, name, read_at).where("#{Nomen::Indicator[name].datatype}_value" => value)
        ids += data.pluck(:product_id) if data.any?
      end
      where(id: ids)
    }

    scope :not_indicate, lambda { |indicator_values, options = {}|
      read_at = options[:at] || Time.zone.now
      ids = []
      # TODO: Build conditions to filter on indicator_values
      indicator_values.each do |name, value|
        # puts name.inspect.yellow
        data = ProductReading.of_products(self, name, read_at).where("#{Nomen::Indicator[name].datatype}_value" => value)
        ids += data.pluck(:product_id) if data.any?
      end
      where.not(id: ids)
    }
  end

  # Register a value at the current value
  def mark!(indicator, options = {})
    marked_at = options[:marked_at] ||= Time.zone.now
    read!(indicator, get!(indicator, at: marked_at), at: marked_at)
  end

  # Measure a product for a given indicator
  def read!(indicator, value, options = {})
    unless indicator.present? && (indicator.is_a?(Nomen::Item) || (indicator = Nomen::Indicator.find(indicator)))
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    raise ArgumentError, 'Value must be given' if value.nil?
    unless options[:force]
      if frozen_indicators.include?(indicator)
        raise ArgumentError, "A frozen indicator (#{indicator.name}) cannot be read"
      end
    end
    options[:at] = Time.new(1, 1, 1, 0, 0, 0, '+00:00') if options[:at] == :origin
    options[:at] = Time.zone.now unless options.key?(:at)
    unless reading = readings.find_by(indicator_name: indicator.name, read_at: options[:at])
      reading = readings.build(indicator_name: indicator.name, read_at: options[:at], originator: options[:originator])
    end
    reading.value = value
    reading.save!
    reading
  end

  # Return the indicator reading
  def reading(indicator, options = {})
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicator[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    read_at = options[:at] || Time.zone.now
    indicator_name = indicator.name
    readings.where(indicator_name: indicator.name).where('read_at <= ?', read_at).order(read_at: :desc).first
  end

  def first_reading(indicator_name)
    candidates = readings.where(indicator_name: indicator_name).order(:read_at)
    return candidates.first if candidates.any?
    nil
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :interpolate is true, it returns the interpolated value
  def get(indicator, *args)
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicator[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    options = args.extract_options!
    cast_or_time = args.shift || options[:cast] || options[:at] || Time.zone.now
    value = nil
    if cast_or_time.is_a?(Time) || cast_or_time.is_a?(DateTime)
      # Find value
      if options[:interpolate]
        if [:measure, :decimal, :integer].include?(indicator.datatype)
          raise NotImplementedError, 'Interpolation is not available for now'
        end
        raise StandardError, "Can not use :interpolate option with #{indicator.datatype.inspect} datatype"
      elsif reading = self.reading(indicator.name, at: cast_or_time)
        value = reading.value
      elsif !options[:default].is_a?(FalseClass)
        if indicator.datatype == :measure
          value = 0.0.in(indicator.unit)
        elsif indicator.datatype == :decimal
          value = 0.0
        elsif indicator.datatype == :integer
          value = 0
        end
      end
      # Adjust value
      if value && indicator.gathering && !options[:gathering].is_a?(FalseClass)
        if indicator.gathering == :proportional_to_population
          value *= send(:population, at: cast_or_time)
        end
      end
    elsif cast_or_time.is_a?(InterventionProductParameter)
      if cast_or_time.product && cast_or_time.product.whole_indicators_list.include?(indicator.name.to_sym)
        value = cast_or_time.send(indicator.name)
      elsif cast_or_time.parameter.new?
        unless variant = cast_or_time.variant || cast_or_time.parameter.variant(cast_or_time.intervention)
          raise StandardError, "Need variant to know how to read it (#{cast_or_time.intervention.procedure_name}##{cast_or_time.reference_name})"
        end
        if variant.frozen_indicators.include?(indicator)
          value = variant.get(indicator)
        else
          raise StandardError, "Cannot find a frozen indicator #{indicator.name} for variant"
        end
      elsif reading = self.reading(indicator.name, at: cast_or_time.intervention.started_at)
        value = reading.value
      else
        raise 'What ?'
      end
      # Adjust value
      if value && indicator.gathering && !options[:gathering].is_a?(FalseClass)
        if indicator.gathering == :proportional_to_population
          value *= cast_or_time.population
        end
      end
    else
      raise "Cannot support #{cast_or_time.inspect} parameter"
    end
    value
  end

  def get!(indicator, *args)
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicator[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    unless value = get(indicator, *args)
      raise "Cannot get value of #{indicator.name} for product ##{id}"
    end
    value
  end

  def density(numerator, denominator, options = {})
    # Check indicator
    unless numerator.is_a?(Nomen::Item) || numerator = Nomen::Indicator[numerator]
      raise ArgumentError, "Unknown indicator #{numerator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    unless denominator.is_a?(Nomen::Item) || denominator = Nomen::Indicator[denominator]
      raise ArgumentError, "Unknown indicator #{denominator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end

    # Find dimension and unit
    numerator_dimension   = Nomen::Dimension.find_by(symbol: numerator.symbol)
    denominator_dimension = Nomen::Dimension.find_by(symbol: denominator.symbol)
    unless dimension = Nomen::Dimension.find_by(symbol: "#{numerator_dimension.symbol}/#{denominator_dimension.symbol}")
      raise "No dimension found for: #{numerator.symbol}/#{denominator.symbol}"
    end
    unless unit = Nomen::Unit.find_by(dimension: dimension)
      raise "No unit found for: #{dimension.inspect}"
    end

    # Compute calculation
    (get(numerator, options).to_d(numerator_dimension.symbol) /
     get(denominator, options).to_d(denominator_dimension.symbol)).in(unit)
  end

  # Read only whole indicators and store it with given options
  def read_whole_indicators_from!(source, options = {})
    whole_indicators_list.each do |indicator|
      value = source.send(indicator)
      read!(indicator, value, options) if value
    end
  end

  # Copy individual indicators of the other at given times
  def copy_readings_of!(other, options = {})
    options[:at] ||= Time.zone.now
    options[:taken_at] ||= options[:at] - 0.000001
    (other.individual_indicators_list - frozen_indicators_list).each do |indicator_name|
      if reading = other.reading(indicator_name, at: options[:taken_at])
        read!(indicator_name, reading.value, at: options[:at], originator: options[:originator])
      end
    end
  end

  def substract_and_read(operand, options = {})
    compute_and_read(operand, options.merge(operation: :substract))
  end

  def add_and_read(operand, options = {})
    compute_and_read(operand, options.merge(operation: :add))
  end

  # Substract a value to a list of indicator data
  def compute_and_read(operand, options = {})
    read_at = options[:at] || Time.zone.now
    taken_at = options[:taken_at] || read_at - 0.000001
    operation = options[:operation] || :add
    whole_indicators_list.each do |indicator_name|
      operand_value = operand.send(indicator_name)
      unless operand_value
        raise StandardError, "No given #{indicator_name} value"
      end
      indicator = Nomen::Indicator.find(indicator_name)
      # Perform operation
      value = get(indicator, at: taken_at)
      value = Charta.new_geometry(value) if indicator.datatype == :shape
      if operation == :add
        value += operand_value
      elsif operation == :substract
        value -= operand_value
      else
        raise StandardError, "Unknown operation: #{operation.inspect}"
      end
      # Read new value
      reading = readings.find_or_initialize_by(
        indicator_name: indicator_name,
        read_at: read_at,
        originator: options[:originator]
      )
      reading.value = value
      reading.save!
    end
  end

  # Substract a value to a list of indicator data
  def substract_to_readings(indicator, value, options = {})
    operate_on_readings(indicator, value, options.merge(operation: :substract))
  end

  # Substract a value to a list of indicator data
  def add_to_readings(indicator, value, options = {})
    operate_on_readings(indicator, value, options.merge(operation: :add))
  end

  def operate_on_readings(indicator, value, options = {})
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicator[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    data = readings.where(indicator_name: indicator.name)
    operation = options.delete(:operation)
    data = data.where('read_at <= ?', options[:before]) if options[:before]
    data = data.where('read_at >= ?', options[:after]) if options[:after]
    if operation == :add
      expr = (indicator.datatype == :shape ? 'ST_Union(VALUE, ?)' : 'VALUE + ?')
    elsif operation == :substract
      expr = (indicator.datatype == :shape ? 'ST_Difference(VALUE, ?)' : 'VALUE - ?')
    else
      raise StandardError, "Unknown operation: #{operation.inspect}"
    end
    data.update_all(["VALUE = #{expr}".gsub('VALUE', "#{indicator.datatype}_value"), value])
  end
end
