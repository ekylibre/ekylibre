# Measure represents a decimal value and a unit.
# It depends on nomenclatures Unit and Dimension.
class Measure
  class AmbiguousUnit < ArgumentError
  end

  class IncompatibleDimensions < ArgumentError
  end

  class InvalidExpression < ArgumentError
  end

  attr_reader :unit, :value
  cattr_reader :dimensions
  delegate :symbol, to: :nomenclature_unit

  @@dimensions = Nomen.find_or_initialize(:dimensions)
  @@units      = Nomen.find_or_initialize(:units)

  class << self
    # Lists all units. Can be filtered on a given dimension
    def units(dimension = nil)
      return @@units.all unless dimension
      unless @@dimensions.all.include?(dimension.to_s)
        fail ArgumentError, "Unknown dimension #{dimension.inspect}"
      end
      @@units.items.select do |_n, i|
        i.dimension.to_s == dimension.to_s
      end.keys.map(&:to_sym)
    end

    # Returns the units of same dimension of the given unit
    def siblings(unit)
      units(dimension(unit))
    end

    # Returns the dimension of the given unit
    def dimension(unit)
      @@units[unit].dimension.to_sym
    end
  end

  # Ways to instanciate a measure:
  # $ Measure.new(55.23, 'kilogram')
  # $ Measure.new(55.23, :kilogram)
  # $ Measure.new('55.23 kilogram')
  # $ Measure.new('55.23kilogram')
  # $ Measure.new('55.23 kg')
  # $ Measure.new('55.23kg')
  # $ 55.23.in_kilogram
  # $ 55.23.in(:kilogram)
  # $ 55.23.in('kilogram')
  def initialize(*args)
    value = nil
    unit = nil
    if args.size == 1
      expr = args.shift.to_s.gsub(/[[:space:]]+/, ' ').strip
      unless expr =~ /\A-?([\,\.]\d+|\d+([\,\.]\d+)?)\s*[^\s]+\z/
        fail InvalidExpression, "#{expr} cannot be parsed."
      end
      unit  = expr.gsub(/\A-?([\,\.]\d+|\d+([\,\.]\d+)?)\s*/, '').strip
      value = expr[0..-unit.size].strip.to_d # expr.split(/[a-zA-Z\s]/).first.strip.gsub(/\,/, '.').to_d
    elsif args.size == 2
      value = args.shift
      unit  = args.shift
    else
      fail ArgumentError, "wrong number of arguments (#{args.size} for 1 or 2)"
    end
    value = 0 if value.blank?
    unless value.is_a? Numeric
      fail ArgumentError, "Value can't be converted to float: #{value.inspect}"
    end
    @value = value.to_r
    unit = unit.name.to_s if unit.is_a?(Nomen::Item)
    @unit = unit.to_s
    unless @@units.items[@unit]
      units = @@units.where(symbol: @unit)
      if units.size > 1
        fail AmbiguousUnit, "The unit #{@unit} match with too many units: #{units.map(&:name).to_sentence}."
      elsif units.size.zero?
        fail ArgumentError, "Unknown unit: #{unit.inspect}"
      else
        @unit = units.first.name.to_s
      end
    end
  end

  # Returns a new measure in the given unit
  def convert(unit)
    Measure.new(to_r(unit), unit)
  end
  alias in convert

  # Converts measure inline without instanciating a new Measure
  def convert!(unit)
    @value = to_r(unit)
    @unit = unit.to_s
    self
  end
  alias in! convert!

  Measure.units.each do |unit|
    define_method "in_#{unit}".to_sym do
      self.in(unit)
    end
  end

  def round(ndigits = 0)
    Measure.new(to_d.round(ndigits), unit)
  end

  def inspect
    "#{@value.to_f} #{@unit}"
  end

  def to_s
    inspect
  end

  # Returns the dimension of a measure
  def dimension
    self.class.dimension(unit)
  end

  # Test if the other measure is equal to self
  def !=(other)
    return true unless other.is_a?(Measure)
    to_r != other.to_r(unit)
  end

  # Test if the other measure is equal to self
  def ==(other)
    return false unless other.is_a?(Measure)
    to_r == other.to_r(unit)
  end

  # Returns if self is less than other
  def <(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be compared to another measure'
    end
    to_r < other.to_r(unit)
  end

  # Returns if self is greater than other
  def >(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be compared to another measure'
    end
    to_r > other.to_r(unit)
  end

  # Returns if self is less than or equal to other
  def <=(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be compared to another measure'
    end
    to_r <= other.to_r(unit)
  end

  # Returns if self is greater than or equal to other
  def >=(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be compared to another measure'
    end
    to_r >= other.to_r(unit)
  end

  # Returns if self is greater than other
  def <=>(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be compared to another measure'
    end
    to_r <=> other.to_r(unit)
  end

  # Test if measure is null
  def zero?
    @value.zero?
  end

  # Returns the dimension of a other
  def +(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be added to another measure'
    end
    self.class.new(@value + other.to_r(unit), unit)
  end

  def -(other)
    unless other.is_a?(Measure)
      fail ArgumentError, 'Only measure can be substracted to another measure'
    end
    self.class.new(@value - other.to_r(unit), unit)
  end

  # Returns opposite of its value
  def -@
    self.class.new(-value, unit)
  end

  # Returns self of its value
  def +@
    self
  end

  def *(numeric_or_measure)
    if numeric_or_measure.is_a? Numeric
      self.class.new(@value * numeric_or_measure.to_r, unit)
    elsif numeric_or_measure.is_a? Measure
      # Find matching dimension
      # Convert
      fail NotImplementedError
    else
      fail ArgumentError, 'Only numerics and measures can be multiplicated to a measure'
    end
  end

  def /(numeric_or_measure)
    if numeric_or_measure.is_a? Numeric
      self.class.new(@value / numeric_or_measure.to_r, unit)
    elsif numeric_or_measure.is_a? Measure
      # Find matching dimension
      # Convert
      if dimension == numeric_or_measure.dimension
        to_d / numeric_or_measure.to_d(unit)
      else
        fail NotImplementedError
      end
    else
      fail ArgumentError, 'Only numerics and measures can divide to a measure'
    end
  end

  def to_r(other_unit = nil, precision = 16)
    if other_unit.nil?
      return value
    else
      other_unit = other_unit.name if other_unit.is_a?(Nomen::Item)
      unless @@units[other_unit]
        fail ArgumentError, "Unknown unit: #{other_unit.inspect}"
      end
      if @@units[unit.to_s].dimension != @@units[other_unit.to_s].dimension
        fail IncompatibleDimensions, "Measure can't be converted from one dimension (#{@@units[unit].dimension}) to an other (#{@@units[other_unit].dimension})"
      end
      return value if unit.to_s == other_unit.to_s
      # Reduce to base
      ref = @@units[unit]
      reduced = ((ref.a * value.to_d(precision)) / ref.d) + ref.b
      # Coeff to dest
      ref = @@units[other_unit]
      return (ref.d * ((reduced - ref.b) / ref.a)).to_r
    end
  end

  # Return Float value
  def to_f(unit = nil, precision = 16)
    to_r(unit, precision).to_f
  end

  # Return BigDecimal value
  def to_d(unit = nil, precision = 16)
    to_r(unit, precision).to_d(precision)
  end

  # Localize a measure
  # FIXME: Measure l10n must be configurable in translation files.
  def localize(options = {})
    "#{value.to_f.localize(options)} #{@@units.items[unit].symbol}"
  end
  alias l localize

  # Returns the unit from the nomenclature
  def nomenclature_unit
    @@units[unit]
  end
end
