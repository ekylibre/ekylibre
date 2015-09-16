module ActiveSensor

  ### DSL ###
  class Controller
    cattr_accessor(:parameters) { {} }

    # Load access parameters supplied by user
    def connect_sensor(access_parameters)
      access_parameters.each do |k, v|
        set_parameter(k, v)
      end
    end

    def get_parameter(attribute)
      parameters.fetch(attribute.to_sym, {})
    end

    def set_parameter(attribute, value)
      parameters[attribute.to_sym] = value
    end

    class << self

      def has_parameter(attribute, options = {})
        default = options.delete(:default)

        ActiveSensor::Parameter.new attribute.to_sym, default
      end

    end
  end
end