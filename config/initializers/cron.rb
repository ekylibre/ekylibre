require 'jobs/all_sensors_reading_job'
require 'jobs/activity_production_check_job'

unless ENV['CRON'] && ENV['CRON'].to_i.zero?
  # Clean cron jobs
  Sidekiq::Cron::Job.destroy_all!

  Sidekiq::Cron::Job.create(name: 'Sensor reading - every hour', cron: '5 * * * *', klass: 'AllSensorsReadingJob')
  Sidekiq::Cron::Job.create(name: 'Detect activity production change - every day', cron: '5 1 * * *', klass: 'ActivityProductionCheckJob')
end
