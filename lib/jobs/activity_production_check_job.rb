class ActivityProductionCheckJob < ActiveJob::Base
  queue_as :default

  def perform
    Ekylibre::Tenant.switch_each do
      today = Date.today
      if ActivityProduction.where(started_on: today).any?
        Ekylibre::Hook.publish(:activity_production_start)
      elsif ActivityProduction.where(stopped_on: today - 1).any?
        Ekylibre::Hook.publish(:activity_production_stop)
      end
    end
  end
end
