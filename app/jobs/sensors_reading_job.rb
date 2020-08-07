class SensorsReadingJob < ApplicationJob
  queue_as :default

  def perform(options = {})
    Sensor.retrieve_all(options.merge(background: true))
  end
end
