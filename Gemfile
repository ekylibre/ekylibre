source 'https://rubygems.org'

gem 'rails', '3.2.12'

# Database adapters
gem 'pg' # Needed for some tasks
gem 'activerecord-postgis-adapter'
gem 'activerecord-spatialite-adapter'

# General
gem 'exception_notification'

# Views helpers
gem 'active-list'
gem 'haml'
gem 'turbolinks'

# Models helpers
gem 'acts_as_list'
gem 'state_machine'
gem 'awesome_nested_set'
gem 'enumerize'
# gem 'paper_trail'

# Authentication
gem 'devise'

# Attachments
gem 'paperclip'

# Forms
gem 'simple_form'
gem 'formize', '~> 1.0.0'
gem 'cocoon'

# I18n
gem 'i18n-complements'

# XML Parsing/Writing
gem 'nokogiri'
gem 'libxml-ruby', :require => 'libxml'

# Reporting
# gem 'thinreports-rails'
# jasper_rails need rjb which need $ sudo apt-get install openjdk-7-jdk and set JAVA_HOME and add a line in environement.rb
gem 'rjb'
gem 'jasper-rails', :git => 'git://github.com/fortesinformatica/jasper-rails.git'
gem 'prawn', '~> 0.12.0'

# Import/Export
gem 'fastercsv'
gem 'rgeo-shapefile'
gem 'rubyzip', :require => 'zip/zip'

# Demo data
gem 'ffaker'

# Javascript framework
gem 'jquery-rails'
# gem 'jquery_mobile_rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'oily_png'
  gem 'compass-rails'
  gem 'zurb-foundation'
  gem 'foundation-icons-sass-rails'
  gem 'turbo-sprockets-rails3'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'libv8', '~> 3.11.8'
  gem 'therubyracer', :platform => :ruby # , '~> 0.10.2'

  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'capybara'
  gem 'rspec-rails'
  gem 'cucumber-rails'
  gem 'awesome_print'
  gem 'pry'
  # database_cleaner is not required, but highly recommended
  gem 'database_cleaner'
  gem "simplecov", :require => false
end

group :development do
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rails_best_practices'

  gem 'thin'
end
