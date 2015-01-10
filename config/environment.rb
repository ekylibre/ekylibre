# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Fix "undefined local variable or method `version_requirements' for #<Rails::GemDependency:0x...>"
if Gem::VERSION >= "1.3.6"
  module Rails
    class GemDependency
      def requirement
        r = super
        (r == Gem::Requirement.default) ? nil : r
      end
    end
  end
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "haml"
  config.gem "fastercsv"
  config.gem "libxml-ruby", :lib=>'libxml'
  config.gem "rubyzip", :lib=>"zip/zip", :version => '~> 0.9.9'
  # config.gem "RedCloth", :lib=>"redcloth"
  # config.gem "measure"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  config.plugins = [ :will_paginate, :dyke, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = :'fr-FR'
end

#Xil.options[:features] += [:template,:document]
#Xil.options[:subdir_size] = 4
if defined? WillPaginate
  WillPaginate::ViewHelpers.pagination_options[:previous_label] = I18n.t('general.previous')
  WillPaginate::ViewHelpers.pagination_options[:next_label] = I18n.t('general.next')
end

# ExceptionNotifier.exception_recipients = %w(dev@ekylibre.org dev@fdsea33.fr)
ExceptionNotifier.exception_recipients = %w(dev@fdsea33.fr)
ExceptionNotifier.sender_address =  %("Ekylibre Error" <notifier@ekylibre.org>)
