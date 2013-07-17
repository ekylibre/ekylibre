require 'nomen'

class Measure
  attr_reader :value, :unit
  cattr_reader :dimensions

  @@dimensions = Nomen::Dimensions
  @@units = Nomen::Units

  class << self

    def units(dimension = nil)
      return @@units.all unless dimension
      raise ArgumentError.new("Unknown dimension #{dimension.inspect}") unless @@dimensions.all.include?(dimension)
      @@units.items.select do |i|
        i.dimension == dimension
      end.map(&:dimension)
    end

    def dimension(unit)
      @@units.items[unit].dimension
    end
  end

  def initialize(value, unit)
    raise ArgumentError.new("Value can't be converted to float: #{value.inspect}") unless value.is_a? Numeric
    @value = value.to_d
    @unit = unit.to_sym
    raise ArgumentError.new("Unknown unit: #{unit.inspect}") unless @@units.items[@unit]
  end

  def convert(unit)
    Measure.new(self.to_d(unit), unit)
  end

  def inspect
    "#{@value.inspect}#{@unit}"
  end

  def to_s
    @value.to_d.to_s + @unit.to_s
  end

  # Returns the dimension of a measure
  def dimension
    self.class.dimension(@unit)
  end

  # Returns the dimension of a measure
  def +(measure)
    raise ArgumentError.new("Only measure can be added to another measure") unless measure.is_a?(Measure)
    self.class.new(@value + measure.to_d(@unit), @unit)
  end

  def -(measure)
    raise ArgumentError.new("Only measure can be substracted to another measure") unless measure.is_a?(Measure)
    self.class.new(@value - measure.to_d(@unit), @unit)
  end

  def to_d(unit = nil)
    if unit.nil?
      return @value
    else
      raise Exception.new("Unknown unit: #{unit.inspect}") unless @@units.all.include? unit
      raise Exception.new("Measure can't be converted from one dimension (#{@@units[@unit].dimension}) to an other (#{@@units[unit].dimension})") if @@units[@unit].dimension != @@units[unit].dimension
      value = @value
      # Reduce to base
      # Coeff to dest
      return value
    end
  end

  # Return
  def to_f
    self.to_d.to_f
  end

end

class ::Numeric

  eval(Measure.units.inject("") do |code, unit|
         code << "def #{unit}\n"
         code << "  Measure.new(self, :#{unit})\n"
         code << "end\n"
         code
       end)

end

