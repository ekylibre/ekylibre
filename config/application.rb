require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ekylibre
  class Application < Rails::Application
    # @return [Array<Ekylibre::Plugin::Base>]
    attr_reader :plugins

    def initialize(*args, **opts, &block)
      super

      @plugins = []
    end

    # @return [Procedo::ProcedureRegistry]
    def procedo_registry
      @procedo_registry ||= Procedo::ProcedureRegistry.new
    end

    # @return [Array<Ekylibre::Plugin::Theme>]
    def themes
      plugins.flat_map(&:themes).map { |name| Ekylibre::Plugin::Theme.new(name) }
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('app', 'models', 'bookkeepers')
    config.autoload_paths << Rails.root.join('app', 'models', 'lexicon')

    # We want to use the structure.sql file
    config.active_record.schema_format = :sql

    config.active_record.time_zone_aware_types = [:datetime, :time]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Confiure ActiveJob queue adapter
    config.active_job.queue_adapter = :sidekiq

    # Default starting from Rails 5
    # TODO: enable this when all optional belongs_to have been edited with 'optional: true'
    config.active_record.belongs_to_required_by_default = false

    # TODO: enable this when ready
    # config.action_controller.per_form_csrf_tokens = true
    # config.action_controller.forgery_protection_origin_check = true

    # Configure defaults for generators
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
    end

    # APM
    config.elastic_apm.service_name = ENV.fetch('APM_SERVICE_NAME', 'Ekylibre')

    config.middleware.use Rack::Cors do
      allow do
        origins /https:\/\/ekylibre.stoplight.io\.*/
        resource '*', 
          headers: :any,
          methods: %i[get post put patch delete]
      end
    end

    # TODO: Rails 5 upgrade: check if removing this is OK
    # config.middleware.insert_after ActionDispatch::ParamsParser, ActiveSupport::XMLConverter

    initializer :register_core_plugin, before: :load_config_initializers do
      Ekylibre::Application.instance.plugins << Ekylibre::Core::Plugin.new
    end

    initializer :after_append_asset_paths, group: :all, after: :append_assets_path do
      { 'jquery-ui-rails' => ['app/assets/images'],
        'active_list' => ['app/assets/images'],
        'bootstrap-sass' => ['assets/images', 'assets/fonts'] }.each do |gem, paths|
        root = Pathname.new(Gem.loaded_specs[gem].full_gem_path)
        paths.each do |path|
          config.assets.paths.delete_if { |p| p.to_s == root.join(path).to_s }
        end
      end
    end
  end
end
