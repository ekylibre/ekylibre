# Abstract Job which permit to run code on each tenant
class ScheduleJob < ActiveJob::Base
  def perform
    perform_on_each_tenant
  end

  def perform_on_each_tenant
    Ekylibre::Tenant.load!
    Ekylibre::Tenant.switch_each do
      perform_on_tenant
    end
  end

  def perform_on_tenant
    raise NotImplementedError
  end
end
