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
  config.excluded_models = %w{}

  # use postgres schemas?
  #config.use_schemas = true

  # use raw SQL dumps for creating postgres schemas? (only appies with use_schemas set to true)
  #config.use_sql = true

  # configure persistent schemas (E.g. hstore )
  config.persistent_schemas = %w{ postgis }

  # add the Rails environment to database names?
  #config.prepend_environment = false
  #config.append_environment = false
  # supply list of database names for migrations to run on
  config.tenant_names = lambda{ Ekylibre::Tenant.list }
end
##
# Elevator Configuration
# Rails.application.config.middleware.use 'Apartment::Elevators::Generic', lambda { |request|
# # TODO: supply generic implementation
# }
# Rails.application.config.middleware.use 'Apartment::Elevators::Domain'
Rails.application.config.middleware.use 'Apartment::Elevators::Subdomain'


# Apartment.configure do |config|

#   config.default_schema = 'public'
#   # config.persistent_schemas = ['public']
#   config.use_schemas = true

#   config.prepend_environment = false

#   config.tenant_names = Ekylibre::Tenant.list

#   # if Rails.env.production?
#   # else
#   #   config.tenant_names = ["farm"]
#   #   # Apartment::Tenant.switch("farm")
#   # end

# end
