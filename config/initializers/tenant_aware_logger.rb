# Logger that shows the tenant when logging.

class TenantAwareLogger < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, progname, message)
    tenant_info = "#{"[#{Rails.env.upcase} - #{Ekylibre::Tenant.current}]".yellow}"
    message_with_tenant = "#{tenant_info.ljust(35 + 8, ' ')} #{message}"
    super(severity, timestamp, progname, message_with_tenant)
  end
end

class DetailedTenantAwareLogger < Logger::Formatter
  def call(severity, timestamp, progname, message)
    message_with_tenant = "#{"[#{Rails.env.upcase} - #{Ekylibre::Tenant.current}]".yellow} #{message}"
    super(severity, timestamp, progname, message_with_tenant)
  end
end
