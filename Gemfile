source 'https://rubygems.org'

ruby '2.2.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'

# Database adapters
gem 'pg' # Needed for some tasks
gem 'activerecord-postgis-adapter', '>= 3.0.0'

# Multi-tenancy
gem 'apartment', '~> 1.0.0', '< 2.0'
gem 'apartment-sidekiq'

# Ruby syntax extensions
gem 'possibly'

# Code manipulation
gem 'code_string'
gem 'charlock_holmes'

gem 'browser'

gem 'actionpack-xml_parser'

# Manage env vars
gem 'figaro'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 2.0'
gem 'jquery-turbolinks'

# jQuery UI Javascript framework
gem 'jquery-ui-rails'
# gem 'jquery_mobile_rails'
gem 'jquery-scrollto-rails'

# Forms helper
gem 'formize', '~> 2.1.0'
# gem 'codemirror-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
# gem 'rails-api'
gem 'kaminari'

# Freeze time for demo and/or tests
gem 'timecop'

# Manage daemons
gem 'foreman'

# Background jobs
gem 'sidekiq', '>= 4.0'
gem 'sidekiq-cron', '>= 0.4.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn', group: :production

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Exception management
gem 'exception_notification'

# Views helpers
gem 'haml'
gem 'simple_calendar'
gem 'active_list', '>= 6.6.0' # , path: "../active_list"

# Models helpers
gem 'uuidtools'
gem 'acts_as_list'
gem 'state_machine'
gem 'awesome_nested_set', '~> 3.0.0'
gem 'enumerize'
gem 'jc-validates_timeliness', '~> 3.1.1'
gem 'deep_cloneable', '~> 2.2.1'

# Authentication & Authorization
gem 'devise'
gem 'devise_invitable'
gem 'devise-i18n-views'
gem 'omniauth'
gem 'omniauth-oauth2'

# Attachments
gem 'paperclip'
gem 'paperclip-document', '> 0.0.8'

# Forms
gem 'simple_form', '~> 3.2.0'
gem 'cocoon'
gem 'remotipart', '~> 1.2'

# I18n and localeapp
gem 'i18n-complements', '>= 0.0.14'
gem 'http_accept_language'
gem 'i18n-js', '>= 3.0.0.rc12'

# XML Parsing/Writing, HTML extraction
gem 'nokogiri', '~> 1.6.0'

# Parse LALR or LR-1 grammars
gem 'treetop'

# Reporting
# Need rjb which need openjdk-7-jdk (sudo apt-get install openjdk-7-jdk)
gem 'beardley', '~> 1.3.0' # , path: "../beardley"
gem 'beardley-barcode'
gem 'beardley-batik'
gem 'beardley-charts'
gem 'beardley-groovy'
gem 'beardley-xml'
gem 'beardley-open_sans'

# Import/Export
gem 'ofx-parser', git: 'https://github.com/lcoq/ofx-parser.git', branch: 'master'
gem 'rgeo-shapefile'
gem 'rgeo-geojson'
gem 'rubyzip'
gem 'roo'
gem 'rodf'

# Demo data
gem 'ffaker', '>= 2.0.0'

# Reading RSS feeds
gem 'feedjira', require: false

# Adds colors in terminal
gem 'colored' # , require: false

# S/CSS Framework
gem 'bootstrap-sass', '~> 3.1'
gem 'twitter-typeahead-rails'

# Iconic font
gem 'agric', '~> 3.0'

# Web services
gem 'mechanize'
gem 'savon'
gem 'rubyntlm', '>= 0.3.2'
gem 'rest-client', require: false

gem 'luhn'

group :development do
  gem 'quiet_assets'
  # gem 'rack-mini-profiler'

  # Code metrics
  gem 'rails_best_practices', require: false
  gem 'rubocop', require: false

  # Webservers
  gem 'thin'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'letter_opener'
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-inline'
  gem 'teaspoon-jasmine'
end

group :test do
  gem 'shoulda-context'

  gem 'capybara'
  gem 'capybara-webkit'
  gem 'selenium-webdriver'

  gem 'database_cleaner'
  gem 'coveralls', '>= 0.6', require: false
  gem 'minitest-reporters'
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob File.expand_path('../{Gemfile.local,Gemfile.plugins,lib/plugins/*/Gemfile}', __FILE__)
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)
  eval_gemfile(file)
end
