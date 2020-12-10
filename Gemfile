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

gem 'elastic-apm', '~> 3.4.0'
gem 'piwik_analytics', github: 'ekylibre/piwik-ruby-tracking'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.11.1'

gem 'webpacker', '~> 4.x'

# Security fix for mail
gem 'mail', '~> 2.6'

# Database adapters
gem 'activerecord-postgis-adapter', '>= 3.0.0'
gem 'pg', '~> 0.20.0' # Needed for some tasks

# Multi-tenancy
gem 'apartment', '~> 2.2.1'
gem 'apartment-sidekiq'

# Ruby syntax extensions
gem 'possibly', gitlab: 'ekylibre/eky-possibly', tag: 'v3.1.1'

# Code manipulation
gem 'charlock_holmes'
gem 'code_string', '>= 0.0.1'

gem 'browser'

gem 'actionpack-xml_parser'

# Maintenance mode
gem 'turnout'

# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Exception analysis and metrics
gem 'binding_of_caller'
gem 'redis-namespace'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'jquery-turbolinks'
gem 'turbolinks', '~> 2.0'

# jQuery UI Javascript framework
gem 'jquery-ui-rails'
# gem 'jquery_mobile_rails'
gem 'jquery-scrollto-rails'

# Forms helper
gem 'formize', '~> 2.1.0'
# gem 'codemirror-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

gem 'rake', '~>12.0'

# Manipulate map data
gem 'charta', '~> 0.1.18'
gem 'geocoder'

# active_list alternative
gem 'font-awesome-sass'
gem 'kaminari', '~> 0.16.0'
gem 'wice_grid' # , github: "leikind/wice_grid", branch: "rails3"

# Background jobs
gem 'sidekiq', '~> 4.0'
gem 'sidekiq-cron', '~> 1.1'
gem 'sidekiq-unique-jobs', '~> 4.0'

# Decorator pattern
gem 'draper'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Exception management
gem 'exception_notification'

gem 'onoma', "~> 0.4.2"

# Views helpers
gem 'active_list', "~> 8.0"
gem 'haml'
gem 'simple_calendar', '~> 2.3.0'

# Models helpers
gem 'acts_as_list'
gem 'awesome_nested_set', '~> 3.1.1'
gem 'deep_cloneable', '~> 2.2.1'
gem 'enumerize'
gem 'validates_timeliness', '~> 4'
gem 'state_machine'
gem 'uuidtools'

# Hide and restore records without actually deleting them
gem "paranoia", "~> 2.2"

# Authentication & Authorization
gem 'devise'
gem 'devise-i18n-views'
gem 'devise_invitable'
gem 'omniauth'
gem 'omniauth-oauth2'

# Attachments
gem 'paperclip'
gem 'paperclip-document', '> 0.0.8'

# Forms
gem 'cocoon'
gem 'remotipart', '~> 1.2'
gem 'simple_form', '~> 3.4'

# I18n and localeapp
gem 'http_accept_language'
gem 'humanize'
gem 'i18n-complements', '>= 0.0.14'
gem 'i18n-js', '>= 3.0.0.rc12'

# Dates management
gem 'time_diff'

# Bool management
gem 'wannabe_bool'

# XML Parsing/Writing, HTML extraction
gem 'nokogiri', '~> 1.8'
gem 'mimemagic'

# Parse LALR or LR-1 grammars
gem 'treetop'

# Reporting
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

# IRB (already require by other gem but some sependencies seems to be missing in ruby 2.6.x ...
gem 'irb'
gem 'fiddle'

# Import/Export
gem 'ekylibre-ofx-parser'
gem 'rgeo-geojson'
gem 'rgeo-shapefile'
gem 'roo'
gem 'rubyzip', '~> 1.2.2'
gem 'sepa_king'
gem 'quandl'
gem 'odf-report', gitlab: 'ekylibre/odf-report', tag: 'v0.6.0-2'
gem 'combine_pdf'
gem 'rodf'

# Demo data
gem 'ffaker', '>= 2.0.0'

# Reading RSS feeds
gem 'feedjira', require: false

# Adds colors in terminal
gem 'colored' # , require: false

# S/CSS Framework
gem 'bootstrap-sass', '~> 3.4.1'
gem 'twitter-typeahead-rails'

# Iconic font
gem 'agric', '~> 4.1'

# Web services
gem 'mechanize'
gem 'rest-client', require: false
gem 'rubyntlm', '>= 0.3.2'
gem 'savon'

gem 'luhn'

# For interval selector
gem 'bootstrap-slider-rails'

gem 'gpgme'

gem 'semantic'

gem 'sprockets', '< 4.0'

group :production do
  # Use unicorn as the app server
  gem 'unicorn'

  gem 'loofah'
end

group :development do
  gem 'bullet', '< 5.6.0'

  gem 'quiet_assets'
  # gem 'rack-mini-profiler'

  # Get the time of a process
  gem 'ruby-prof'

  gem 'better_errors'

  # Code metrics
  gem 'rails_best_practices', require: false
  gem 'rubocop', '~> 1.3.1', require: false
  gem 'parser', '~> 2.7.1.5'

  # Webservers
  gem 'thin'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'letter_opener'
end

group :development, :test do
  gem 'pry', '~> 0.12.0'
  gem 'pry-byebug'
  # gem 'pry-inline'
  gem 'pry-rails'
  gem 'teaspoon-jasmine'

  # For git manipulation in test:git task
  gem 'git'

  # Parallelize tests
  gem 'parallel_tests'

  # Exception message tips
  gem 'did_you_mean', '~> 0.9', platforms: [:ruby_22]

  gem 'yard'

  gem 'dotenv'
end

group :test do
  # Freeze time for demo and/or tests
  gem 'timecop'

  gem 'puma'
  gem 'shoulda-context'

  gem 'database_cleaner'

  gem 'minitest-reporters'
  gem 'ruby-terminfo'

  gem 'factory_bot', '< 5'

  gem 'pdf-reader'
end

# Load Gemfile.local, Gemfile.plugins, plugins', and custom Gemfiles
gemfiles = Dir.glob File.expand_path('../{Gemfile.local,Gemfile.plugins,plugins/*/Gemfile}', __FILE__)
gemfiles << ENV['CUSTOM_PLUGIN_GEMFILE'] unless ENV['CUSTOM_PLUGIN_GEMFILE'].nil?
gemfiles.each do |file|
  next unless File.readable?(file)
  eval_gemfile(file)
end
