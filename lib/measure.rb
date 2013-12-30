# -*- coding: utf-8 -*-
require 'nomen'

class AmbiguousUnit < ArgumentError
end

class IncompatibleDimensions < ArgumentError
end

class InvalidExpression < ArgumentError
end

class Measure
  attr_reader :value, :unit
  cattr_reader :dimensions

  @@dimensions = Nomen::Dimensions
  @@units      = Nomen::Units

  class << self

    # Lists all units. Can be filtered on a given dimension
    def units(dimension = nil)
      return @@units.all unless dimension
      raise ArgumentError.new("Unknown dimension #{dimension.inspect}") unless @@dimensions.all.include?(dimension.to_s)
      @@units.items.select do |n, i|
        i.dimension.to_s == dimension.to_s
      end.keys.map(&:to_sym)
    end

    # Returns the units of same dimension of the given unit
    def siblings(unit)
      return self.units(self.dimension(unit))
    end

    # Returns the dimension of the given unit
    def dimension(unit)
      @@units[unit].dimension.to_sym
    end

  end

  # Ways to instanciate a measure
  # $ Measure.new(55.23, "kilogram")
  # $ Measure.new(55.23, :kilogram)
  # $ Measure.new("55.23 kilogram")
  # $ Measure.new("55.23kilogram")
  # $ 55.23.in_kilogram
  # $ 55.23.in(:kilogram)
  # $ 55.23.in("kilogram")
  def initialize(*args)
    value, unit = nil, nil
    if args.size == 1
      expr  = args.shift.to_s.gsub(/[[:space:]]+/, ' ').strip
      unless expr.match(/\A([\,\.]\d+|\d+([\,\.]\d+)?)\s*[a-zA-Z].*\z/)
        raise InvalidExpression, "#{expr} cannot be parsed."
      end
      unit  = expr.gsub(/\A[\d\.\,\s]+/, '')
      value = expr.split(/[a-zA-Z\s]/).first.strip.gsub(/\,/, '.').to_d
    elsif args.size == 2
      value = args.shift
      unit  = args.shift
    else
      raise ArgumentError, "wrong number of arguments (#{args.size} for 1 or 2)"
    end
    unless value.is_a? Numeric
      raise ArgumentError, "Value can't be converted to float: #{value.inspect}"
    end
    @value = value.to_r
    if unit.is_a?(Nomen::Item)
      unit = unit.name.to_s
    end
    @unit = unit.to_s
    unless @@units.items[@unit]
      units = @@units.where(symbol: @unit)
      if units.size > 1
        raise AmbiguousUnit, "The unit #{@unit} match with too many units: #{units.map(&:name).to_sentence}."
      elsif units.size.zero?
        raise ArgumentError, "Unknown unit: #{unit.inspect}"
      else
        @unit = units.first.name.to_s
      end
    end
  end

  def convert(unit)
    return (@unit == unit.to_s ? self : Measure.new(self.to_r(unit), unit))
  end
  alias :in :convert

  eval(Measure.units.inject("") do |code, unit|
         code << "def in_#{unit}\n"
         code << "  self.in(:#{unit})\n"
         code << "end\n"
         code
       end)

  def round(ndigits=0)
    Measure.new(self.to_d.round(ndigits), self.unit)
  end

  def inspect
    "#{@value.to_f} #{@unit}"
  end

  def to_s
    inspect
  end

  # Returns the dimension of a measure
  def dimension
    self.class.dimension(@unit)
  end

  # Test if the other measure is equal to self
  def ==(other)
    to_d == other.to_d(@unit)
  end

  # Returns the dimension of a measure
  def +(measure)
    unless measure.is_a?(Measure)
      raise ArgumentError, "Only measure can be added to another measure"
    end
    self.class.new(@value + measure.to_r(@unit), @unit)
  end

  def -(measure)
    unless measure.is_a?(Measure)
      raise ArgumentError, "Only measure can be substracted to another measure"
    end
    self.class.new(@value - measure.to_r(@unit), @unit)
  end

  def *(numeric_or_measure)
    if numeric_or_measure.is_a? Numeric
      self.class.new(@value * numeric_or_measure.to_r, @unit)
    elsif numeric_or_measure.is_a? Measure
      # Find matching dimension
      # Convert
      raise NotImplementedError.new
    else
      raise ArgumentError, "Only numerics and measures can be multiplicated to a measure"
    end
  end

  def /(numeric_or_measure)
    if numeric_or_measure.is_a? Numeric
      self.class.new(@value / numeric_or_measure, @unit)
    elsif numeric_or_measure.is_a? Measure
      # Find matching dimension
      # Convert
      raise NotImplementedError.new
    else
      raise ArgumentError, "Only numerics and measures can divide to a measure"
    end
  end

  def to_r(unit = nil)
    if unit.nil?
      return @value
    else
      unit = unit.name if unit.is_a?(Nomen::Item)
      unless @@units[unit]
        raise ArgumentError, "Unknown unit: #{unit.inspect}"
      end
      if @@units[@unit.to_s].dimension != @@units[unit.to_s].dimension
        raise IncompatibleDimensions, "Measure can't be converted from one dimension (#{@@units[@unit].dimension}) to an other (#{@@units[unit].dimension})"
      end
      # Reduce to base
      ref = @@units[@unit]
      reduced = ((ref.a * @value) / ref.d) + ref.b
      # Coeff to dest
      ref = @@units[unit]
      value = ref.d * ((reduced - ref.b) / ref.a)
      return value.to_r
    end
  end

  # Return Float value
  def to_f(unit = nil)
    self.to_r(unit).to_f
  end

  # Return BigDecimal value
  def to_d(unit = nil, precision = 16)
    self.to_r(unit).to_d(precision)
  end

  # Localize a measure
  def l
    "#{self.value.to_f.l} #{@@units.items[@unit].symbol}"
  end

end

class ::Numeric

  eval(Measure.units.inject("") do |code, unit|
         code << "def in_#{unit}\n"
         code << "  Measure.new(self, :#{unit})\n"
         code << "end\n"
         code
       end)

  def in(unit)
    Measure.new(self, unit)
  end

end

