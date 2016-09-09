class DailyTriggerJob < ActiveJob::Base
  queue_as :default

  def perform
    Ekylibre::Tenant.switch_each do
      Ekylibre::Hook.publish(:every_day)
    end
  end
end
