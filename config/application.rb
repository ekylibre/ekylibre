require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Load JAVA env variables
begin
  ENV['JAVA_HOME'] ||= `readlink -f /usr/bin/java | sed "s:/jre/bin/java::"`.strip
  architecture = `dpkg --print-architecture`.strip
  ENV['LD_LIBRARY_PATH'] = "#{ENV['LD_LIBRARY_PATH']}:#{ENV['JAVA_HOME']}/jre/lib/#{architecture}:#{ENV['JAVA_HOME']}/jre/lib/#{architecture}/client"
rescue
  puts "JAVA_HOME has not been set automatically because it's not Debian here."
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Ekylibre
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fra
    config.i18n.locale = :fra

    # Configure defaults for generators
    config.generators do |g|
      g.orm             :active_record
      g.template_engine :haml
    end

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
