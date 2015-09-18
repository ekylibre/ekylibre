# ActiveSensor provides a way to collect data from sensors.
# In this first version, sensor are supposed to be read on regular interval
module ActiveSensor
  class EquipmentNotFound < StandardError
  end

  class MissingParameter < StandardError
  end

  autoload :Connection, 'active_sensor/connection'
  autoload :Controller, 'active_sensor/controller'
  autoload :Equipment, 'active_sensor/equipment'
  autoload :Parameter, 'active_sensor/parameter'
end
