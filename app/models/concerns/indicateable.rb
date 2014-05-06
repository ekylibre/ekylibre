module Indicateable
  extend ActiveSupport::Concern

  included do
    has_many :readings, class_name: "ProductReading", dependent: :destroy, inverse_of: :product

    scope :indicate, lambda { |indicator_values, options = {}|
      read_at = options[:at] || Time.now
      ids = []
      # TODO Build conditions to filter on indicator_values
      for name, value in indicator_values
        data = ProductReading.of_products(self, name, read_at).where("#{Nomen::Indicators[name].datatype}_value" => value)
        if data.any?
          ids << data.pluck(:product_id)
        end
      end
      where(id: ids)
    }

    scope :not_indicate, lambda { |indicator_values, options = {}|
      read_at = options[:at] || Time.now
      ids = []
      # TODO Build conditions to filter on indicator_values
      for name, value in indicator_values
        data = ProductReading.of_products(self, name, read_at).where("#{Nomen::Indicators[name].datatype}_value" => value)
        if data.any?
          ids << data.pluck(:product_id)
        end
      end
      where.not(id: ids)
    }

  end

  # Deprecated method to call net_surface_area
  # Will be removed in Ekylibre 1.1
  def area(unit = :hectare, at = Time.now)
    ActiveSupport::Deprecation.warn("Product#area is deprecated. Please use Product#net_surface_area instead.")
    return net_surface_area(at).in(unit)
  end

  # Deprecated method to call net_mass
  # Will be removed in Ekylibre 1.1
  def mass(unit = :kilogram, at = Time.now)
    ActiveSupport::Deprecation.warn("Product#mass is deprecated. Please use Product#net_mass instead.")
    return net_mass(at).in(unit)
  end

  # Permits to always return a population
  def population(*args)
    return self.get(:population, *args) || 0.0
  end

  # Measure a product for a given indicator
  def read!(indicator, value, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    if value.nil?
      raise ArgumentError, "Value must be given"
    end
    if !options[:force] and self.frozen_indicators.include?(indicator)
      raise ArgumentError, "A frozen indicator (#{indicator.name}) cannot be read"
    end
    options[:at] = Time.new(1, 1, 1, 0, 0, 0, "+00:00") if options[:at] == :origin
    options[:at] = Time.now unless options.has_key?(:at)
    unless reading = self.readings.find_by(indicator_name: indicator.name, read_at: options[:at])
      reading = self.readings.build(indicator_name: indicator.name, read_at: options[:at], originator: options[:originator])
    end
    reading.value = value
    reading.save!
    return reading
  end

  # Return the indicator reading
  def reading(indicator, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    read_at = options[:at] || Time.now
    return self.readings.where(indicator_name: indicator.name).where("read_at <= ?", read_at).reorder(read_at: :desc).first
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :interpolate is true, it returns the interpolated value
  def get(indicator, *args)
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    options = args.extract_options!
    cast_or_time = args.shift || options[:cast] || options[:at] || Time.now
    value = nil
    if cast_or_time.is_a?(Time)
      # Find value
      if options[:interpolate]
        if [:measure, :decimal, :integer].include?(indicator.datatype)
          raise NotImplementedError, "Interpolation is not available for now"
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
      if value and indicator.gathering and !options[:gathering].is_a?(FalseClass)
        if indicator.gathering == :proportional_to_population
          value *= self.send(:population, at: cast_or_time)
        end
      end
    elsif cast_or_time.is_a?(InterventionCast)
      if cast_or_time.actor and cast_or_time.actor.whole_indicators_list.include?(indicator.name.to_sym)
        value = cast_or_time.send(indicator.name)
      elsif cast_or_time.reference.new?
        unless variant = cast_or_time.variant || cast_or_time.reference.variant(cast.intervention)
          raise StandardError, "Need variant to know how to read it"
        end
        if variant.frozen_indicators.include?(indicator)
          value = variant.get(indicator)
        else
          raise StandardError, "Cannot find a frozen indicator #{indicator.name} for variant"
        end
      elsif reading = self.reading(indicator.name, at: cast_or_time.intervention.started_at)
        value = reading.value
      else
        raise "What ?"
      end
      # Adjust value
      if value and indicator.gathering and !options[:gathering].is_a?(FalseClass)
        if indicator.gathering == :proportional_to_population
          value *= cast_or_time.population
        end
      end
    else
      raise "Cannot support #{cast_or_time.inspect} parameter"
    end
    return value
  end


  def get!(indicator, *args)
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    unless value = get(indicator, *args)
      raise "Cannot get value of #{indicator.name} for product ##{self.id}"
    end
    return value
  end

  # # Returns indicators for a set of product
  # def self.readings(name, options = {})
  #   read_at = options[:at] || Time.now
  #   ProductReading.where("id IN (SELECT p1.id FROM #{self.indicator_table_name(name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator = p2.indicator AND (p1.read_at < p2.read_at OR (p1.read_at = p2.read_at AND p1.id < p2.id)) AND p2.read_at <= ?) WHERE p1.read_at <= ? AND p1.product_id IN (?) AND p1.indicator = ? AND p2 IS NULL)", read_at, read_at, self.pluck(:id), name)
  # end


  def density(numerator, denominator, options = {})
    # Check indicator
    unless numerator.is_a?(Nomen::Item) or numerator = Nomen::Indicators[numerator]
      raise ArgumentError, "Unknown indicator #{numerator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    unless denominator.is_a?(Nomen::Item) or denominator = Nomen::Indicators[denominator]
      raise ArgumentError, "Unknown indicator #{denominator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end

    # Find dimension and unit
    numerator_dimension   = Nomen::Dimensions.find_by(symbol: numerator.symbol)
    denominator_dimension = Nomen::Dimensions.find_by(symbol: denominator.symbol)
    unless dimension = Nomen::Dimensions.find_by(symbol: "#{numerator_dimension.symbol}/#{denominator_dimension.symbol}")
      raise "No dimension found for: #{numerator.symbol}/#{denominator.symbol}"
    end
    unless unit = Nomen::Units.find_by(dimension: dimension)
      raise "No unit found for: #{dimension.inspect}"
    end
    
    # Compute calculation
    return (self.get(numerator, options).to_d(numerator_dimension.symbol) / 
            self.get(denominator, options).to_d(denominator_dimension.symbol)).in(unit)
  end


  # Copy individual indicators of the other at given times
  def copy_readings_of!(other, options = {})
    options[:at] ||= Time.now
    options[:taken_at] ||= options[:at]
    for indicator_name in other.individual_indicators_list - self.frozen_indicators_list
      if reading = other.reading(indicator_name, at: options[:taken_at])
        self.read!(indicator_name, reading.value, at: options[:at], originator: options[:originator])
      end
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
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    data = self.readings.where(indicator_name: indicator.name)
    operation = options.delete(:operation)
    if options[:before]
      data = data.where("read_at <= ?", options[:before])
    end
    if options[:after]
      data = data.where("read_at >= ?", options[:after])
    end
    if operation == :add
      expr = (indicator.datatype == :shape ? "ST_Union(VALUE, ?)" : "VALUE + ?")
    elsif operation == :substract
      expr = (indicator.datatype == :shape ? "ST_Difference(VALUE, ?)" : "VALUE - ?")
    else
      raise StandardError, "Unknown operation: #{operation.inspect}"
    end
    data.update_all(["VALUE = #{expr}".gsub("VALUE", "#{indicator.datatype}_value"), value])
  end


end
