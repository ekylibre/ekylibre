module Ekylibre
  module Job
    class Base < ActiveJob::Base
      rescue_from(Exception) do |exception|
        # retry_job wait: 5.minutes, queue: :low_priority
        ExceptionNotifier.notify_exception(exception, data: { message: 'was doing something wrong' })
      end

      before_enqueue do |job|
        puts Ekylibre::Tenant.current.inspect.red
        job.arguments << Ekylibre::Tenant.current
      end

      around_perform do |job, block|
        tenant = job.arguments.delete_at(-1)
        puts tenant.inspect.blue
        Ekylibre::Tenant.switch(tenant) do
          block.call
        end
      end
    end
  end
end
