class HourlyTriggerJob < ActiveJob::Base
  queue_as :default

  def perform
    Ekylibre::Tenant.switch_each do
      Ekylibre::Hook.publish(:every_hour)
    end
  end
end
