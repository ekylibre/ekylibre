# Abstract Job which permit to run code on each tenant
class ScheduleJob < ApplicationJob
  def perform
    perform_on_each_tenant
  end

  def perform_on_each_tenant
    Ekylibre::Tenant.load!
    Ekylibre::Tenant.switch_each do |tenant|
      begin
        perform_on_tenant
      rescue StandardError => e
        Rails.logger.error("#{self.class.name} failed on tenant '#{tenant}': #{e.class}: #{e.message}")
        ExceptionNotifier.notify_exception(e, data: { job: self.class.name, tenant: tenant })
      end
    end
  end

  def perform_on_tenant
    raise NotImplementedError
  end
end
