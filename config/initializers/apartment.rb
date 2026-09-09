# Require whichever elevator you're using below here...
#
# require 'apartment/elevators/generic'
# require 'apartment/elevators/domain'
require 'apartment/elevators/subdomain'
require 'apartment/adapters/postgresql_adapter'
#
# Apartment Configuration
#
Apartment.configure do |config|
  # These models will not be multi-tenanted,
  # but remain in the global (public) namespace
  #
  # An example might be a Customer or Tenant model that stores each tenant information
  # ex:
  #
  # config.excluded_models = %w{Tenant}
  #
  config.excluded_models = %w[]

  # use postgres schemas?
  config.use_schemas = true

  # use raw SQL dumps for creating postgres schemas? (only applies with use_schemas set to true)
  config.use_sql = true

  # Postgis default Schema must be "postgis"
  config.persistent_schemas = %w[postgis lexicon]

  # add the Rails environment to database names?
  # config.prepend_environment = false
  # config.append_environment = false
  # supply list of database names for migrations to run on

  config.tenant_names = -> { Ekylibre::Tenant.list }
end

module Apartment
  module Elevators
    # Resolves the tenant from `X-Tenant` header (used by Duke and other
    # service-to-service calls), falling back to the request subdomain so
    # browser navigation (`closeriedesterres.ekylibre.localhost`) keeps working.
    # Inheriting Subdomain reuses its host parsing for the fallback path.
    class Header < Apartment::Elevators::Subdomain
      def parse_tenant_name(request)
        return request.env['HTTP_X_TENANT'] if request.env['HTTP_X_TENANT'].present?
        super
      end
    end

    class SecuredSubdomain < Apartment::Elevators::Subdomain
      def call(env)
        request = Rack::Request.new(env)
        return @app.call(env) if request.path.start_with?('/admin')
        super
      rescue ::Apartment::TenantNotFound
        request = Rack::Request.new(env)
        Rails.logger.error "Apartment Tenant not found: #{subdomain(request.host)}"
        return [404, { 'Content-Type' => 'text/html' }, [File.read(Rails.root.join('public', '404.html'))]]
      end
    end
  end

  module Adapters
    class PostgresqlSchemaAdapter < Apartment::Adapters::AbstractAdapter
      protected

        # Overrides ros-apartment's implementation for two reasons:
        #
        # 1. Upstream raises ActiveRecord::StatementInvalid when the schema is
        #    missing (TenantNotFound only comes from the rescue path). The app
        #    keys its 404 handling on TenantNotFound — see the SecuredSubdomain
        #    elevator above and ApplicationController's rescue_from.
        # 2. No `rescue *rescuable_exceptions`: wrapping every ActiveRecordError
        #    into TenantNotFound masks genuine database failures as "unknown
        #    tenant", which is both misleading and a 404 where a 500 is due.
        #
        # The connection liveness check gives a clearer error than the
        # NoDatabaseError that would otherwise surface further down.
        def connect_to_new(tenant = nil)
          return reset if tenant.nil?

          unless Apartment.connection.active?
            raise ActiveRecord::StatementInvalid, "Could not establish connection to database for schema #{tenant}"
          end

          raise TenantNotFound, "Could not find schema #{tenant}. Search path: [#{full_search_path}]" unless schema_exists?(tenant)

          @current = tenant.is_a?(Array) ? tenant.map(&:to_s) : tenant.to_s
          Apartment.connection.schema_search_path = full_search_path
        end
    end

    class PostgresqlSchemaFromSqlAdapter < PostgresqlSchemaAdapter
      # ros-apartment freezes PSQL_DUMP_BLACKLISTED_STATEMENTS, so the previous
      # `<<` appends now raise FrozenError. Rebuild the constant from upstream's
      # value instead of restating it, so new upstream entries keep flowing in.
      #
      # Why each addition is needed:
      #   CREATE SCHEMA  - upstream only filters `CREATE SCHEMA public`, but
      #                    db/structure.sql declares every schema it dumps and
      #                    Apartment creates the tenant schema itself.
      #   \restrict /    - psql 16+ dump markers; they are meaningless to the
      #   \unrestrict     SQL executor and abort the load.
      EXTRA_BLACKLISTED_STATEMENTS = [
        /CREATE SCHEMA/i,
        /\\restrict/i,
        /\\unrestrict/i
      ].freeze

      statements = (PSQL_DUMP_BLACKLISTED_STATEMENTS + EXTRA_BLACKLISTED_STATEMENTS).freeze
      remove_const(:PSQL_DUMP_BLACKLISTED_STATEMENTS) if const_defined?(:PSQL_DUMP_BLACKLISTED_STATEMENTS, false)
      const_set(:PSQL_DUMP_BLACKLISTED_STATEMENTS, statements)
    end
  end
end

if ENV['TENANT']
  Rails.application.config.middleware.use Apartment::Elevators::Generic, proc { |request|
    next nil if request.path.start_with?('/admin')
    ENV['TENANT']
  }
elsif Rails.env.test?
  Rails.application.config.middleware.use Apartment::Elevators::Generic, proc { |_request| 'test' }
elsif ENV['ELEVATOR'] == 'header'
  Rails.application.config.middleware.use Apartment::Elevators::Header
else
  Rails.application.config.middleware.use Apartment::Elevators::SecuredSubdomain
end

if ENV['HOST_SUBDOMAIN_NAME'].present?
  Apartment::Elevators::SecuredSubdomain.excluded_subdomains = ENV['HOST_SUBDOMAIN_NAME']
end
