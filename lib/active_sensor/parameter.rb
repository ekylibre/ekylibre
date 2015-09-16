module ActiveSensor
  class Parameter < ActiveSensor::Controller
    def initialize(attribute, default = nil)
      parameters[attribute] = default
    end
  end
end