# Non persistent model to manage indicator data
class IndicatorDatum

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
      # elsif datatype == :multi_polygon
      #   factory = RGeo::Cartesian.simple_factory
      #   if object.is_a?(WellKnownBinary)
      #     object = WKRep::WKBParserfactory.parse_wkb(object)
      #   elsif object.is_a?(String)
      #     object = factory.parse_wkt(object)
      #   end
      #   object = factory.multi_polygon(object)
      elsif datatype == :decimal
        object = object.to_d
      end
    end
    @value = object
  end

end
