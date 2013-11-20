class IndicatorDatum < Ekylibre::Record::Base
  self.abstract_class = true
  enumerize :indicator, in: Nomen::Indicators.all, default: Nomen::Indicators.default, predicates: {prefix: true}
  enumerize :indicator_datatype, in: Nomen::Indicators.datatype.choices, predicates: {prefix: true}
  enumerize :measure_value_unit, in: Nomen::Units.all, predicates: {prefix: true}

  composed_of :measure_value, class_name: "Measure", :mapping => [%w(measure_value_value value), %w(measure_value_unit unit)]

  validates_inclusion_of :indicator, in: self.indicator.values
  validates_inclusion_of :indicator_datatype, in: self.indicator_datatype.values

  validates_presence_of :point_value,    if: :indicator_datatype_point?
  validates_presence_of :multi_polygon_value, if: :indicator_datatype_multi_polygon?
  validates_presence_of :string_value,   if: :indicator_datatype_string?
  validates_presence_of :measure_value,  if: :indicator_datatype_measure?
  validates_inclusion_of :boolean_value, in: [true, false], if: :indicator_datatype_boolean?
  validates_presence_of :choice_value,   if: :indicator_datatype_choice?
  validates_presence_of :decimal_value,  if: :indicator_datatype_decimal?

  # Keep this format to ensure inheritance
  before_validation :set_datatype
  validate :validate_value

  def set_datatype
    self.measured_at ||= Time.now
    self.indicator_datatype = self.theoric_datatype
  end

  def validate_value
    if self.indicator_datatype_measure?
      # TODO Check unit
      # errors.add(:unit, :invalid) if unit.dimension != indicator.unit.dimension
    end
  end

  # Read value from good place
  def value
    datatype = self.indicator_datatype || self.theoric_datatype
    self.send(datatype.to_s + '_value')
  end

  # Write value into good place
  def value=(object)
    datatype = (self.indicator_datatype || self.theoric_datatype).to_sym
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
    self.send(datatype.to_s + '_value=', object)
    # puts [object, self.attributes].inspect
    # puts self.valid?.inspect
    # puts self.attributes.inspect
    # puts self.errors.inspect
  end

  # Retrieve datatype from nomenclature NOT from database
  def theoric_datatype
    # return nil if self.indicator.blank?
    Nomen::Indicators.items[self.indicator].datatype.to_sym
  end

  def indicator_name
    self.indicator.tl
  end

end
