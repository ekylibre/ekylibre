class ScheduledPhytosanitaryRegisterArchiveJob < ScheduleJob
  queue_as :low

  def perform_on_tenant
    year = Time.zone.today.year - 1
    return unless Entity.of_company&.in_france?

    Rails.logger.info "[phyto register] scheduled archive for tenant=#{Apartment::Tenant.current} year=#{year}"
    PhytosanitaryRegisterArchiveJob.perform_now(year: year)
  rescue StandardError => e
    Rails.logger.error "[phyto register] scheduled archive failed: #{e.message}"
    ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
  end
end
