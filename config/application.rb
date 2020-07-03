require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ekylibre
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('app', 'models', 'bookkeepers')

    # We want to use the structure.sql file
    config.active_record.schema_format = :sql

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.available_locales = %i[eng fra]
    I18n.config.enforce_available_locales = false
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :eng
    config.i18n.locale = :eng

    # Confiure ActiveJob queue adapter
    config.active_job.queue_adapter = :sidekiq

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Configure defaults for generators
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
    end

    # APM
    config.elastic_apm.service_name = ENV.fetch('APM_SERVICE_NAME', 'Ekylibre')

    # config.middleware.use Rack::Cors do
    #   allow do
    #     origins '*'
    #     resource '*', :headers => :any, :methods => [:get, :post]
    #   end
    # end

    config.middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser

    # Configure layouts for devise
    config.to_prepare do
      Devise::SessionsController.layout 'authentication'
      Devise::RegistrationsController.layout proc { |_controller| user_signed_in? ? 'backend' : 'authentication' }
      Devise::ConfirmationsController.layout 'authentication'
      Devise::UnlocksController.layout 'authentication'
      Devise::PasswordsController.layout 'authentication'
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
