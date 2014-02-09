# Non persistent model to manage indicator data
class Reading

  def initialize(indicator, value)
    unless @indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator: #{indicator.inspect}"
    end
    @value = value
  end

  def datatype
    @indicator.datatype
  end

  def name
    @indicator.name
  end

  def value
    @value
  end

  def value=(object)
    datatype = @indicator.datatype.to_sym
    if object.is_a?(String)
      if datatype == :measure
        object = Measure.new(object)
      elsif datatype == :boolean
        object = ["1", "ok", "t", "true", "y", "yes"].include?(object.to_s.strip.downcase)
      elsif datatype == :decimal
        object = object.to_d
      end
    end
    @value = object
  end

end
