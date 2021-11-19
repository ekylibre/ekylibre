# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

git_source(:gitlab) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://gitlab.com/#{repo_name}.git"
end

ruby '>= 2.6.6', '< 3.0.0'

gem 'actionpack-xml_parser', '~> 2.0'
gem 'rack-cors' # CORS policy
gem 'rails', '5.0.7.2'
gem 'turnout', '~> 2.5' # Maintenance mode

# IRB and CLI
gem 'colored' # , require: false
gem 'fiddle'
gem 'irb', '~> 1.3'
gem 'rake', '~> 12.0'

# TO REMOVE ASAP
gem 'browser', '~> 5.2' # Only used in ApplicationController to check for IE
gem 'ffaker', '~> 2.0' # Should not be present in production. Is used to generate names for Products.
gem 'rjb', '1.6.2' # Version 1.6.4 segfaults on test server, jasper repors should be trashed anyway....
gem 'time_diff', '~> 0.3.0' # Only used in InterventionWorkingPeriod
gem 'wannabe_bool', '~> 0.7.1' # This Gem is a JOKE

# Database
gem 'activemodel-serializers-xml', '~> 1.0'
gem 'activerecord-postgis-adapter', '~> 4.1'
gem 'pg', '~> 1.0'

# Multi-tenancy
gem 'apartment', '~> 2.2.1'
gem 'apartment-sidekiq', '~> 1.2'

# Assets pipeline
gem 'coffee-rails', '~> 4.1'
gem 'sassc-rails', '~> 2.0'
gem 'sprockets', '< 4.0'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 4.x'

# CSS
gem 'agric', github: 'ekylibre/agric', branch: 'master'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'bootstrap-slider-rails', '~> 9.8'
gem 'font-awesome-sass', '~> 5.15'

# JS
gem 'cocoon', '~> 1.2'
gem 'jquery-rails', '~> 4.4'
gem 'jquery-ui-rails', '~> 6.0'
gem 'momentjs-rails', '>= 2.9.0'
gem 'simple_calendar', '~> 2.4.0'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5.2.1'
gem 'twitter-typeahead-rails', '~> 0.11.1'

# Front
gem 'active_list', gitlab: 'ekylibre/active_list', branch: 'master'
gem 'formize', '~> 2.1.0'
gem 'kaminari', '~> 1.1'
gem 'remotipart', '~> 1.2'
gem 'simple_form', '~> 3.4'
gem 'wice_grid', '~> 4.0'

# View Engines
gem 'haml', '~> 5.2'
gem 'jbuilder', '~> 2.0'

# Ruby extensions
gem 'code_string', '~> 0.0.1'
gem 'possibly', gitlab: 'ekylibre/eky-possibly', tag: 'v3.1.1'
gem 'semantic', '~> 1.6'

# Exception analysis and metrics
gem 'binding_of_caller', '~> 1.0'
gem 'elastic-apm', '~> 3.4.0'
gem 'exception_notification', '~> 4.4'
gem 'redis-namespace', '~> 1.8'

# Manipulate map data
gem 'charta', '~> 0.3.0'
gem 'geocoder', '~> 1.6'
gem 'rgeo', '~> 2.2'
gem 'rgeo-geojson', '~> 2.1'
gem 'rgeo-shapefile', '~> 3.0'

# Background jobs
gem 'sidekiq', '~> 4.0'
gem 'sidekiq-cron', '~> 1.1'
gem 'sidekiq-unique-jobs', '~> 4.0'

# Reference data
gem 'onoma', '~> 0.6.2'

# Parse LALR or LR-1 grammars
gem 'treetop', '~> 1.6'

# Models helpers
gem 'acts_as_list', '~> 1.0'
gem 'awesome_nested_set', '~> 3.1.1'
gem 'deep_cloneable', '~> 2.2.1'
gem 'draper', "~> 3.0"
gem 'enumerize', '~> 2.4'
gem 'paranoia', '~> 2.2' # Hide and restore records without actually deleting them
gem 'state_machine', '~> 1.2'
gem 'uuidtools', '~> 2.2'
gem 'validates_timeliness', '~> 4'

# Authentication & Authorization
gem 'devise', '~> 4.7'
gem 'devise-i18n-views', '~> 0.3.7'
gem 'devise_invitable', '~> 2.0'
gem 'omniauth', '~> 1.9'
gem 'omniauth-oauth2', '~> 1.7'

# Attachments
gem 'paperclip', '~> 5.3'
gem 'paperclip-document', '~> 0.0.11'

# I18n and localeapp
gem 'http_accept_language', '~> 2.1'
gem 'humanize', '~> 2.5'
gem 'i18n-complements', '>= 0.0.14'
gem 'i18n-js', '~> 3.8'

# Reporting (Jasper): DEPRECATED
# Need rjb which need openjdk-7-jdk (sudo apt-get install openjdk-7-jdk)
# If you encounter a Segfault related to those gems you need to add
# JAVA_TOOL_OPTIONS=-Xss1280k to your env vars
# cf. https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1699772
gem 'beardley', '~> 1.3'
gem 'beardley-barcode', '>= 1.0.1'
gem 'beardley-batik', '>= 1.0.1'
gem 'beardley-charts', '>= 0.0.1'
gem 'beardley-groovy', '>= 2.0.1'
gem 'beardley-open_sans', '>= 0.0.2'
gem 'beardley-xml', '>= 1.1.2'

# Import/Export
gem 'charlock_holmes', '~> 0.7.7'
gem 'combine_pdf', '~> 1.0'
gem 'ekylibre-ofx-parser', '~> 1.2'
gem 'gpgme', '~> 2.0'
gem 'holidays' # Deal with statutory and other holidays
gem 'luhn', '~> 1.0'
gem 'mimemagic', '~> 0.3.5'
gem 'nokogiri', '~> 1.8'
gem 'odf-report', gitlab: 'ekylibre/odf-report', tag: 'v0.6.0-2'
gem 'prawn', '~> 2.4'
gem 'quandl', '~> 1.1'
gem 'rodf', '~> 1.0'
gem 'roo', '~> 2.8'
gem 'rubyzip', '~> 1.2.2'
gem 'sepa_king', '~> 0.12.0'
gem 'xml_errors_parser', gitlab: 'ekylibre/xsd_errors_parser', branch: 'master'

# Web services
gem 'mechanize', '~> 2.7'
gem 'rest-client', '~> 2.0', require: false
gem 'rubyntlm', '>= 0.3.2'
gem 'savon', '~> 2.12'

# Using git until we have a proper release system for cartography
gem 'cartography', gitlab: 'ekylibre/cartography', branch: 'eky'
# gem 'cartography', path: '../cartography'

group :production do
  # Use unicorn as the app server
  gem 'unicorn', '~> 5.8'
end

group :development do
  gem 'bullet', '< 5.6.0'

  gem 'better_errors', '~> 2.9'
  gem 'rack-mini-profiler'
  # Get the time of a process
  gem 'ruby-prof', '~> 1.4'

  # Code metrics
  gem 'rails_best_practices', '~> 1.20', require: false
  gem 'rubocop', '~> 1.11.0', require: false

  # Webservers
  gem 'rack-handlers'
  gem 'unicorn-rails'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'

  gem 'letter_opener', '~> 1.7'
end

group :development, :test do
  gem 'dotenv', '~> 2.7'

  gem 'pry', '~> 0.12.0'
  gem 'pry-byebug', '~> 3.8'
  gem 'pry-rails', '~> 0.3.9'

  # For git manipulation in test:git task
  gem 'git', '~> 1.8'

  gem 'yard', '~> 0.9.26'
end

group :test do
  # Freeze time for demo and/or tests
  gem 'timecop', '~> 0.9.0'

  gem 'shoulda-context', '~> 2.0'

  gem 'database_cleaner', '~> 1.8'

  gem 'minitest', "~> 5.14"
  gem 'minitest-reporters', '~> 1.4'

  gem 'factory_bot', '< 5'

  gem 'pdf-reader', '~> 2.4'

  gem 'rails-controller-testing', '~> 1.0'
  # for loading lexicon 5 in test mode
  gem 'lexicon-common', '~> 0.2.0'
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob(File.expand_path('../{plugins/*/Gemfile,Gemfile.*}', __FILE__)).keep_if{|e| e !~/(.lock)$/}
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)

  eval_gemfile(file)
end
