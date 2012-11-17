Apartment.configure do |config|
  config.excluded_models = ["Company"]
  # config.database_names = lambda{ Company.scoped.collect(&:database) }
  # config.default_schema = "postgres"
  config.persistent_schemas = ['public']
end
