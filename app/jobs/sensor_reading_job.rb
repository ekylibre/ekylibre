class SensorReadingJob < Ekylibre::Job::Base
  queue_as :default

  def perform(*args)
    Sensor.retrieve_all(args)
  end
end
