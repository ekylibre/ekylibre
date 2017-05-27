class HourlyTriggerJob < ScheduleJob
  queue_as :default

  def perform_on_tenant
    Ekylibre::Hook.publish(:every_hour)
  end
end
