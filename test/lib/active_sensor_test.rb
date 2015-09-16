require 'test_helper'

class ActiveSensorTest < ActiveSupport::TestCase
  test 'should register many equipments' do
    path = Rails.root.join('test', 'fixture-files', 'sensors.yml')
    assert path.exist?, "Sensor fixture file doesn't exist"
    ActiveSensor::Base.register_many(path)

    assert ActiveSensor::Base.list.size > 0, 'No Equipment loaded'
    assert ActiveSensor::Base.list.first.is_a?(ActiveSensor::Equipment), 'Is not a ActiveSensor::Equipment instance'

    assert ActiveSensor::Equipment.vendors.include?(:vendor1), 'Vendor not found'

    assert ActiveSensor::Equipment.equipments_of(:vendor1).collect(&:model).include?(:model1), 'Sensor model not found'

    assert ActiveSensor::Equipment.find(:vendor1, :model1).is_a?(ActiveSensor::Equipment), 'Equipment not found'
  end
end
