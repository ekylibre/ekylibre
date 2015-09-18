require 'jobs/all_sensors_reading_job'

# Clean cron jobs
Sidekiq::Cron::Job.destroy_all!

Sidekiq::Cron::Job.create(name: 'Sensor reading - every hour', cron: '* */1 * * *', klass: 'AllSensorsReadingJob')
