require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Ekylibre
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths << Rails.root.join("lib")

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.available_locales = [:arb, :eng, :fra, :jpn, :spa]
    I18n.config.enforce_available_locales = false
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :eng
    config.i18n.locale = :eng

    # Configure defaults for generators
    config.generators do |g|
      g.orm             :active_record
      g.template_engine :haml
    end

    # config.middleware.use Rack::Cors do
    #   allow do
    #     origins '*'
    #     resource '*', :headers => :any, :methods => [:get, :post]
    #   end
    # end

    # Configure layouts for devise
    config.to_prepare do
      Devise::SessionsController.layout "authentication"
      Devise::RegistrationsController.layout proc{ |controller| user_signed_in? ? "backend" : "authentication" }
      Devise::ConfirmationsController.layout "authentication"
      Devise::UnlocksController.layout "authentication"
      Devise::PasswordsController.layout "authentication"
    end
  end
end
