source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.2'

# Database adapters
gem 'pg' # Needed for some tasks
gem 'activerecord-postgis-adapter'
# gem 'activerecord-spatialite-adapter'
# gem 'squeel'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.1'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
gem 'jquery-turbolinks'

# jQuery UI Javascript framework
gem 'jquery-ui-rails'
# gem 'jquery_mobile_rails'

# Forms helper
gem 'formize', '~> 1.1.0'
# gem 'codemirror-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'ruby-prof'

# General
gem 'exception_notification'

# Views helpers
gem 'haml'
gem "calendar_helper", "~> 0.2.5"
gem "simple_calendar"

# Models helpers
gem 'acts_as_list'
gem 'state_machine'
gem 'awesome_nested_set', '~> 3.0.0.rc2'
gem 'enumerize'
gem 'sneaky-save'
# gem 'paper_trail'

# Authentication
gem 'devise'
gem 'devise-i18n-views'

# Attachments
gem 'paperclip'
gem 'paperclip-document'

# Forms
gem 'simple_form', '~> 3.0.0'
gem 'cocoon'

# I18n and localeapp
gem 'i18n-complements'
# gem 'i18n-spec'
# gem 'localeapp'

# XML Parsing/Writing, HTML extraction
gem 'nokogiri', '~> 1.6.0'
# gem 'libxml-ruby', :require => 'libxml'
gem 'mechanize'
# gem 'savon', '= 2.2.0' # waiting for SOAP and EDE Webservices

# Reporting
# gem 'thinreports-rails'
# Need rjb which need $ sudo apt-get install openjdk-7-jdk and set JAVA_HOME and add a line in environement.rb
gem 'beardley'
# gem 'prawn', '~> 0.12.0'

# Import/Export
gem 'fastercsv'
gem 'rgeo-shapefile'
gem 'rubyzip'
gem 'ofx-parser'

# Demo data
gem 'ffaker'

# Reading RSS feeds
gem 'feedzirra'

# Compass
gem 'compass', '~> 0.13.alpha.10'
gem 'compass-rails', '~> 2.0.alpha.0' # github: 'Compass/compass-rails', branch: 'rails4-hack' # '~> 2.0.alpha.0'
gem 'oily_png'

# Iconic font
gem 'agric'

group :development do
  gem 'quiet_assets'
  # gem 'rack-mini-profiler'
  # gem 'better_errors'
  # gem 'binding_of_caller'
  gem 'rb-readline' # , '~> 0.4.2'

  # Project management
  gem 'rails_best_practices'
  gem 'railroady'
  # gem 'rails-erd', github: "burisu/rails-erd"

  # Webservers
  gem 'unicorn'
  gem 'thin'
end

group :development, :test do
  gem 'factory_girl_rails'
  gem 'spinach-rails'
end

group :test do
  gem 'shoulda-context'
  gem 'headless'
  gem 'capybara'
  # gem 'capybara-webkit'
  gem 'selenium-webdriver'
  gem 'capybara-screenshot'
  gem "launchy"
  gem 'rspec-expectations'
  # gem 'rspec-rails'
  gem 'awesome_print'
  gem 'pry'
  # database_cleaner is not required, but highly recommended
  gem 'database_cleaner'
  gem 'coveralls', '>= 0.6', require: false
end

