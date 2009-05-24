# = Measure
#
# Author:: Kenta Murata
# Copyright:: Copyright (C) 2008 Kenta Murata
# License:: LGPL version 3.0
 
class Measure
  class UnitRedefinitionError < StandardError; end
  class InvalidUnitError < StandardError; end
  class CompatibilityError < StandardError; end
 
  @@units = []
  @@dimension_map = {}
  @@conversion_map = {}
  @@alias_map = {}
 
  class << self
    def conversion_map
      @@conversion_map
    end
 
    def has_unit?(unit)
      begin
        unit = resolve_alias unit
        return @@units.include?(unit)
      rescue InvalidUnitError
        return false
      end
    end
 
    #
    # Resolves an alias and returns the entity.
    # The returned unit is NOT invalid always.
    # InvalidUnitError is raised if a given unit is undefined.
    #
    def resolve_alias(unit)
      # NOTE: mustn't use has_unit? method to avoid infinite recursion
      return unit if @@units.include? unit
      unless @@alias_map.has_key? unit
        raise InvalidUnitError, "unit `#{unit}' is undefined"
      end
      while @@alias_map.has_key? unit
        unit = @@alias_map[unit]
      end
      return unit
    end
 
    #
    # Test direct compatibility between two units, u1 and u2.
    #
    def direct_compatible?(u1, u2)
      u1 = resolve_alias u1
      u2 = resolve_alias u2
      return true if u1 == u2
      if @@conversion_map.has_key? u1 and @@conversion_map[u1].has_key? u2
        return true
      end
      if @@conversion_map.has_key? u2 and @@conversion_map[u2].has_key? u1
        return true unless Proc === @@conversion_map[u2][u1]
      end
      return false
    end
 
    #
    # Clear all defined units.
    #
    def clear_units
      @@units.clear
      @@dimension_map.clear
      @@conversion_map.clear
      @@alias_map.clear
      return nil
    end
 
    #
    # Returns defined units. If dimension is specified, returning
    # units are of only the dimension.
    #
    def units(dimension=nil)
      return @@units.dup if dimension.nil?
      @@dimension_map.select {|k, v| v == dimension }.collect{|k, v| k }
    end
 
    #
    # The number of defined units.
    #
    def num_units
      return @@units.length + @@alias_map.length
    end
 
    #
    # Defines a unit. The default dimension is 1.
    # Measure::UnitRedefinitionError is raised when the unit is redefined.
    #
    def define_unit(unit, dimension=1)
      if @@units.include?(unit)
        if self.dimension(unit) != dimension
          raise UnitRedefinitionError, "unit [#{unit}] is already defined"
        end
      else
        @@units << unit
        @@dimension_map[unit] = dimension
        return self
      end
    end
 
    alias def_unit define_unit
 
    #
    # Defines an alias.
    # Measure::UnitRedefinitionError is raised when the alias is redefined.
    # Measure::InvalidUnitError is raised when the base unit is not defined.
    #
    def define_alias(unit, base)
      if self.has_unit?(unit)
        raise UnitRedefinitionError, "unit [#{unit}] is already defined"
      end
      @@alias_map[unit] = resolve_alias base
    end
 
    alias def_alias define_alias
 
    #
    # Defines conversions.
    #
    #
    def define_conversion(origin, conversion)
      origin = resolve_alias origin
      @@conversion_map[origin] ||= {}
      conversion.each {|target, conv|
        target = resolve_alias target
        @@conversion_map[origin][target] = conv
      }
      return nil
    end
 
    alias def_conversion define_conversion
 
    def undefine_unit(unit)
      if @@units.include? unit
        @@conversion_map.delete unit
        @@conversion_map.each {|k, v| v.delete unit }
        @@units.delete unit
        return true
      elsif @@alias_map.has_key? unit
        @@alias_map.delete unit
        return true
      end
      return false
    end
 
    #
    #
    #
    def dimension(unit)
      return @@dimension_map[resolve_alias(unit)]
    end
    alias dim dimension
 
    def find_conversion_route(u1, u2)
      visited = []
      queue = [[u1]]
      while route = queue.shift
        next if visited.include? route.last
        visited.push route.last
        return route if route.last == u2
        neighbors(route.last).each{|u|
          queue.push(route + [u]) unless visited.include? u }
      end
      return nil
    end
    alias find_multi_hop_conversion find_conversion_route
 
# def encode_dimension(dim)
# case dim
# when Symbol
# return dim.to_s
# else
# units = dim.sort {|a, b| a[1] <=> b[1] }.reverse
# nums = []
# units.select {|u, e| e > 0 }.each {|u, e| nums << "#{u}^#{e}" }
# dens = []
# units.select {|u, e| e < 0 }.each {|u, e| dens << "#{u}^#{-e}" }
# return nums.join(' ') + ' / ' + dens.join(' ')
# end
# end
 
    private
 
    def neighbors(unit)
      res = []
      res += @@conversion_map[unit].keys if @@conversion_map.has_key?(unit)
      @@conversion_map.each {|k, v|
        res << k if v.has_key? unit and not Proc === v[unit] }
      return res
    end
  end # class << self
 
  def initialize(value, unit)
    @value, @unit = value, unit
    return nil
  end
 
  attr_reader :value, :unit
 
  def <(other)
    case other
    when Measure
      if self.unit == other.unit
        return self.value < other.value
      else
        return self < other.convert(self.value)
      end
    when Numeric
      return self.value < other
    else
      raise ArgumentError, 'unable to compare with #{other.inspect}'
    end
  end
 
  def >(other)
    case other
    when Measure
      if self.unit == other.unit
        return self.value > other.value
      else
        return self > other.convert(self.value)
      end
    when Numeric
      return self.value > other
    else
      raise ArgumentError, 'unable to compare with #{other.inspect}'
    end
  end
 
  def ==(other)
    return self.value == other.value if self.unit == other.unit
    if Measure.direct_compatible? self.unit, other.unit
      return self == other.convert(self.unit)
    elsif Measure.direct_compatible? other.unit, self.unit
      return self.convert(other.unit) == other
    else
      return false
    end
  end
 
  def +(other)
    case other
    when Measure
      if self.unit == other.unit
        return Measure(self.value + other.value, self.unit)
      elsif Measure.dim(self.unit) == Measure.dim(other.unit)
        return Measure(self.value + other.convert(self.unit).value, self.unit)
      else
        raise TypeError, "incompatible dimensions: " +
          "#{Measure.dim(self.unit)} and #{Measure.dim(other.unit)}"
      end
    when Numeric
      return Measure(self.value + other, self.unit)
    else
      check_coercable other
      a, b = other.coerce self
      return a + b
    end
  end
 
  def -(other)
    case other
    when Measure
      if self.unit == other.unit
        return Measure(self.value - other.value, self.unit)
      elsif Measure.dim(self.unit) == Measure.dim(other.unit)
        return Measure(self.value - other.convert(self.unit).value, self.unit)
      else
        raise TypeError, "incompatible dimensions: " +
          "#{Measure.dim(self.unit)} and #{Measure.dim(other.unit)}"
      end
    when Numeric
      return Measure(self.value - other, self.unit)
    else
      check_coerecable other
      a, b = other.coerce self
      return a - b
    end
  end
 
  def *(other)
    case other
    when Measure
      return other * self.value if self.unit == 1
      return Measure(self.value * other.value, self.unit) if other.unit == 1
      # TODO: dimension
      raise NotImplementedError, "this feature has not implemented yet"
# if self.unit == other.unit
# return Measure(self.value * other.value, self.unit)
# elsif Measure.dim(self.unit) == Measure.dim(other.unit)
# return Measure(self.value - other.convert(self.unit).value, self.unit)
# else
# return Measure(self.value * other.convert(self.unit).value, self.unit)
# end
    when Numeric
      return Measure(self.value * other, self.unit)
    else
      check_coercable other
      a, b = other.coerce self
      return a * b
    end
  end
 
  def /(other)
    case other
    when Measure
      # TODO: dimension
      raise NotImplementedError, "this feature has not implemented yet"
# if self.unit == other.unit
# return Measure(self.value / other.value, self.unit)
# else
# return Measure(self.value / other.convert(self.unit).value, self.unit)
# end
    when Numeric
      return Measure(self.value / other, self.unit)
    else
      check_coercable other
      a, b = other.coerce self
      return a / b
    end
  end
 
  def coerce(other)
    case other
    when Numeric
      return [Measure(other, 1), self]
    else
      raise TypeError, "#{other.class} can't convert into #{self.class}"
    end
  end
 
  def abs
    return Measure(self.value.abs, self.unit)
  end
 
  def to_s
    return "#{self.value} [#{self.unit}]"
  end
 
  def to_a
    return [self.value, self.unit]
  end
 
  def convert(unit)
    return self if unit == self.unit
    to_unit = Measure.resolve_alias unit
    raise InvalidUnitError, "unknown unit: #{unit}" unless Measure.has_unit? unit
    from_unit = Measure.resolve_alias self.unit
    if Measure.direct_compatible? from_unit, to_unit
      # direct conversion
      if @@conversion_map.has_key? from_unit and @@conversion_map[from_unit].has_key? to_unit
        conv = @@conversion_map[from_unit][to_unit]
        case conv
        when Proc
          value = conv[self.value]
        else
          value = self.value * conv
        end
      else
        value = self.value / @@conversion_map[to_unit][from_unit].to_f
      end
    elsif route = Measure.find_multi_hop_conversion(from_unit, to_unit)
      u1 = route.shift
      value = self.value
      while u2 = route.shift
        if @@conversion_map.has_key? u1 and @@conversion_map[u1].has_key? u2
          conv = @@conversion_map[u1][u2]
          case conv
          when Proc
            value = conv[vaule]
          else
            value *= conv
          end
        else
          value /= @@conversion_map[u2][u1].to_f
        end
        u1 = u2
      end
    else
      raise CompatibilityError, "units not compatible: #{self.unit} and #{unit}"
    end
    # Second
    return Measure.new(value, unit)
  end
 
  alias saved_method_missing method_missing
  private_methods :saved_method_missing
 
  def method_missing(name, *args)
    if /^as_(\w+)/.match(name.to_s)
      unit = $1.to_sym
      return convert(unit)
    end
    return saved_method_missing(name, *args)
  end
 
  private
 
  def check_coercable(other)
    unless other.respond_to? :coerce
      raise TypeError, "#{other.class} can't be coerced into #{self.class}"
    end
  end
end
 
def Measure(value, unit=1)
  return Measure.new(value, unit)
end
