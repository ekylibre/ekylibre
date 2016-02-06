module ActiveSensor
  ### DSL ###
  class Controller
    class << self
      def parameters
        @parameters ||= {}.with_indifferent_access
      end

      def parameters=(hash)
        @parameters = hash.with_indifferent_access
      end

      def inherited(subclass)
        subclass.parameters = parameters
      end

      def has_parameter(name, options = {})
        parameters[name] = ActiveSensor::Parameter.new(name.to_sym, options)
      end
    end

    def retrieve(*_args)
      raise :not_implemented
    end
  end
end
