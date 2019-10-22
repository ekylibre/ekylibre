module Ekylibre
  module Testing
    module Concerns

      module FixturesCleanerModule
        extend ActiveSupport::Concern

        included do
          def before_setup
            @previous_tenant = Ekylibre::Tenant.current
            Ekylibre::Tenant.switch! 'test_without_fixtures'
            DatabaseCleaner.start
            super
          end

          def after_teardown
            super
            DatabaseCleaner.clean
          ensure
            Ekylibre::Tenant.switch! @previous_tenant
          end

          def with_fixtures?
            false
          end
        end
      end

    end
  end
end
