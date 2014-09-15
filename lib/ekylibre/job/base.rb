module Ekylibre
  module Job

    class Base

      include Sidekiq::Worker

      class << self
        def enqueue(*args)
          perform_async(Ekylibre::Tenant.current, *args)
        end
      end

      def perform(tenant, *args)
        Ekylibre::Tenant.switch(tenant)
        work(*args)
      end

      def work(*args)
        raise NotImplementedError
      end

    end

  end
end
