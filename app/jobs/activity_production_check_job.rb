class ActivityProductionCheckJob < ScheduleJob
  queue_as :critical

  def perform_on_tenant
    today = Date.today
    if ActivityProduction.where(started_on: today).any?
      Ekylibre::Hook.publish(:activity_production_start)
    elsif ActivityProduction.where(stopped_on: today - 1).any?
      Ekylibre::Hook.publish(:activity_production_stop)
    end
  end
end
