require 'jobs/all_sensors_reading_job'
require 'jobs/activity_production_check_job'
require 'jobs/equipment_life_progress_check_job'
require 'jobs/hourly_trigger_job'
require 'jobs/daily_trigger_job'

unless ENV['CRON'] && ENV['CRON'].to_i.zero?
  # Clean cron jobs
  Sidekiq::Cron::Job.destroy_all!

  Sidekiq::Cron::Job.create(name: 'Sensor reading - every hour',
                            cron: '5 * * * *',
                            klass: 'AllSensorsReadingJob')
  Sidekiq::Cron::Job.create(name: 'Detect activity production change - every day',
                            cron: '5 1 * * *',
                            klass: 'ActivityProductionCheckJob')
  Sidekiq::Cron::Job.create(name: 'Check on equipments and alerts if they near the end of their lives - three times a day',
                            cron: '1 */7 * * *',
                            klass: 'EquipmentLifeProgressCheckJob')
  # Recurring triggers
  Sidekiq::Cron::Job.create(name: 'Hourly trigger',
                            cron: '1 * * * *',
                            klass: 'HourlyTriggerJob')
  Sidekiq::Cron::Job.create(name: 'Daily trigger',
                            cron: '1 1 * * *',
                            klass: 'DailyTriggerJob')
end
