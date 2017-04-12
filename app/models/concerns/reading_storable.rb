module ReadingStorable
  extend ActiveSupport::Concern

  included do
    refers_to :indicator
    enumerize :indicator_datatype, in: %i[string integer decimal boolean choice measure point geometry multi_polygon], predicates: { prefix: true }
    refers_to :measure_value_unit, class_name: 'Unit'

    has_geometry :geometry_value
    has_geometry :point_value, type: :point
    has_geometry :multi_polygon_value, type: :multi_polygon

    composed_of :measure_value, class_name: 'Measure', mapping: [%w[measure_value_value to_d], %w[measure_value_unit unit]]
    composed_of :absolute_measure_value, class_name: 'Measure', mapping: [%w[absolute_measure_value_value to_d], %w[absolute_measure_value_unit unit]]

    # validates :indicator_name, inclusion: { in: indicator_name.values }
    validates :indicator_datatype, inclusion: { in: indicator_datatype.values }

    validates :boolean_value, inclusion: { in: [true, false], if: :indicator_datatype_boolean? }
    validates :choice_value,   presence: { if: :indicator_datatype_choice? }
    validates :decimal_value,  presence: { if: :indicator_datatype_decimal? }
    validates :geometry_value, presence: { if: :indicator_datatype_geometry? }
    validates :integer_value,  presence: { if: :indicator_datatype_integer? }
    validates :measure_value, :absolute_measure_value, presence: { if: :indicator_datatype_measure? }
    validates :multi_polygon_value, presence: { if: :indicator_datatype_multi_polygon? }
    validates :point_value,    presence: { if: :indicator_datatype_point? }
    validates :string_value,   presence: { if: :indicator_datatype_string? }

    # Keep this format to ensure inheritance
    before_validation :set_datatype
    before_validation :absolutize_measure
    validate :validate_value
  end

  def set_datatype
    unless indicator
      raise "Unknown indicator name in #{self.class.name}##{id}: #{indicator_name.inspect}"
    end
    self.indicator_datatype = indicator.datatype
  end

  def absolutize_measure
    if indicator_datatype_measure? && measure_value.is_a?(Measure)
      self.absolute_measure_value = measure_value.in(indicator.unit)
    end
  end

  def validate_value
    if indicator_datatype_measure?
      # TODO: Check unit
      # errors.add(:unit, :invalid) if unit.dimension != indicator.unit.dimension
    end
  end

  # Read value from good place
  def value
    datatype = indicator_datatype || indicator.datatype
    send(datatype.to_s + '_value')
  end

  # Write value into good place
  def value=(object)
    datatype = (indicator_datatype || indicator.datatype).to_sym
    if object.is_a?(String)
      if datatype == :measure
        object = Measure.new(object)
      elsif datatype == :boolean
        object = %w[1 t true y yes ok].include?(object.to_s.strip.downcase)
      elsif datatype == :decimal
        object = object.to_d
      elsif datatype == :integer
        object = object.to_i
      end
    end
    if datatype == :geometry || datatype == :multi_polygon
      object = Charta.new_geometry(object).transform(:WGS84).to_rgeo
    end
    send("#{datatype}_value=", object)
  end

  def indicator
    Nomen::Indicator[indicator_name]
  end

  def indicator=(item)
    self.indicator_name = item.name
  end

  delegate :human_name, to: :indicator, prefix: true

  # methods defined here are going to extend the class, not the instance of it
  module ClassMethods
    def value_column(indicator_name)
      unless indicator = Nomen::Indicator[indicator_name]
        raise ArgumentError, "Expecting an indicator name. Got #{indicator_name.inspect}."
      end
      { measure: :measure_value_value }[indicator.datatype] || "#{indicator.datatype}_value".to_sym
    end

    def indicator_table_name(_indicator_name)
      table_name
    end
  end
end
