source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1'

# Database adapters
gem 'pg' # Needed for some tasks
gem 'activerecord-postgis-adapter', '>= 3.0.0.beta2'

# Multi-tenancy
gem 'apartment', '< 1.0.0'

# Code manipulation
gem 'code_string'
gem 'charlock_holmes'

gem 'browser'

# Use SCSS for stylesheets
gem 'sass-rails', '5.0.1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
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
gem "jquery-scrollto-rails"

# Forms helper
gem 'formize', '~> 2.1.0'
# gem 'codemirror-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
# gem 'rails-api'

# Freeze time for demo and/or tests
gem 'timecop'

# Background jobs
gem 'sidekiq', require: false

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# General
gem 'exception_notification'

# Views helpers
gem 'haml'
gem "calendar_helper", "~> 0.2.5"
gem "simple_calendar", "~> 0.1"
gem "active_list", '>= 6.4.2' #, path: "../active_list" #

# Models helpers
gem 'acts_as_list'
gem 'state_machine'
gem 'awesome_nested_set', '~> 3.0.0.rc3'
gem 'enumerize'
gem 'jc-validates_timeliness', '~> 3.1.1'

# Authentication & Authorization
gem 'devise'
gem 'devise-i18n-views'

# Attachments
gem 'paperclip', '4.2.0'
gem 'paperclip-document', '>= 0.0.8'

# Forms
gem 'simple_form', '~> 3.1.0'
gem 'cocoon'

# I18n and localeapp
gem 'i18n-complements', '>= 0.0.14'
gem 'http_accept_language'

# XML Parsing/Writing, HTML extraction
gem 'nokogiri', '~> 1.6.0'

# Parse LALR or LR-1 grammars
gem 'treetop'

# Reporting
# Need rjb which need openjdk-7-jdk (sudo apt-get install openjdk-7-jdk)
gem 'beardley', '~> 1.1.0'
gem 'beardley-barcode'
gem 'beardley-batik'
gem 'beardley-charts'
gem 'beardley-groovy'
gem 'beardley-xml'
gem 'beardley-open_sans'

# Import/Export
gem 'fastercsv'
gem 'ofx-parser'
gem 'rgeo-shapefile'
gem 'rgeo-geojson'
gem 'rubyzip'
gem 'roo'
gem 'spreadsheet'

# Demo data
gem 'ffaker', '>= 2.0.0'

# Reading RSS feeds
gem 'feedjira', require: false

# Adds colors in terminal
gem 'colored' #, require: false

# Compass
gem 'compass-rails'
gem 'bootstrap-sass', '~> 3.1'
gem 'oily_png'

# Iconic font
gem 'agric'

# Idele webservices
gem 'mechanize'
gem 'savon', '~> 2.5.1'

group :development do
  gem 'quiet_assets'
  # gem 'rack-mini-profiler'
  # gem 'better_errors'
  # gem 'binding_of_caller'

  # Project management
  gem 'rails_best_practices', '1.15.4'
  # gem 'railroady'
  # gem 'rails-erd', github: "burisu/rails-erd"

  # Webservers
  gem 'unicorn'
  gem 'thin'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'factory_girl_rails'
  gem 'shoulda-context'

  gem 'capybara'
  gem 'capybara-webkit'
  gem 'selenium-webdriver'

  # gem 'awesome_print'
  # gem 'pry'
  gem 'database_cleaner'
  gem 'coveralls', '>= 0.6', require: false
end

