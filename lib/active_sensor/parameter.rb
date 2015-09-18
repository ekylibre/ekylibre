module ActiveSensor
  class Parameter < ActiveSensor::Controller
    attr_reader :name, :type, :default

    def initialize(name, options = {})
      @name = name
      @default = options[:default]
      @required = !options[:required].is_a?(FalseClass)
      @type = options[:type] || :text
    end

    def required?
      @required
    end

    def human_name
      @name.to_s.humanize
    end

    # Check and normalize value
    def normalize!(value)
      if value.blank?
        return default if default
        fail MissingParameter, "Parameter #{@name} cannot be blank" if required?
        return nil
      end
      value
    end
  end
end
