# Require whichever elevator you're using below here...
#
# require 'apartment/elevators/generic'
# require 'apartment/elevators/domain'
require 'apartment/elevators/subdomain'
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
  config.excluded_models = %w()

  # use postgres schemas?
  config.use_schemas = true

  # use raw SQL dumps for creating postgres schemas? (only applies with use_schemas set to true)
  config.use_sql = true

  # Postgis default Schema must be "postgis"
  config.persistent_schemas = %w(postgis)

  # add the Rails environment to database names?
  # config.prepend_environment = false
  # config.append_environment = false
  # supply list of database names for migrations to run on
  config.tenant_names = -> { Ekylibre::Tenant.list }
end

module Apartment
  module Elevators
    # Special elevator which permit to switch on header "X-Tenant"
    class Header < Apartment::Elevators::Generic
      def parse_tenant_name(request)
        return nil unless request.env['HTTP_X_TENANT']
        request.env.each do |k, v|
          # puts "#{k.to_s.rjust(30).yellow}: #{v.to_s.red}"
        end
        # puts request.env.keys.inspect.red
        request.env['HTTP_X_TENANT']
      end
    end

    class SecuredSubdomain < Apartment::Elevators::Subdomain
      def call(env)
        super
      rescue ::Apartment::TenantNotFound
        request = Rack::Request.new(env)
        Rails.logger.error "Apartment Tenant not found: #{subdomain(request.host)}"
        return [404, { 'Content-Type' => 'text/html' }, [File.read(Rails.root.join('public', '404.html'))]]
      end
    end
  end
end

if ENV['TENANT']
  Rails.application.config.middleware.use 'Apartment::Elevators::Generic', proc { |_request| ENV['TENANT'] }
elsif Rails.env.test?
  Rails.application.config.middleware.use 'Apartment::Elevators::Generic', proc { |_request| 'test' }
elsif ENV['ELEVATOR'] == 'header'
  Rails.application.config.middleware.use 'Apartment::Elevators::Header'
else
  Rails.application.config.middleware.use 'Apartment::Elevators::SecuredSubdomain'
end
