class AllSensorsReadingJob < ActiveJob::Base
  queue_as :default

  def perform
    Ekylibre::Tenant.switch_each do
      Rails.logger.info("Background sensors reading of #{Ekylibre::Tenant.current.to_s.red}...")
      SensorsReadingJob.perform_later
      Rails.logger.info("Background sensors reading of #{Ekylibre::Tenant.current.to_s.red}...")
    end
  end
end
