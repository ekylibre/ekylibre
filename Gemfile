source 'https://rubygems.org'

gem 'rails', '3.2.11'

gem 'pg' # Needed for some tasks
gem 'activerecord-postgis-adapter'
gem 'activerecord-spatialite-adapter'

gem 'haml'
gem 'fastercsv'
gem 'libxml-ruby', :require => 'libxml'
gem 'rubyzip', :require => 'zip/zip'
gem 'exception_notification'
gem 'state_machine'
gem 'i18n-complements'
gem 'active-list'
gem 'formize', '~> 1.0'
gem 'prawn', '>= 0.10.0'
gem 'acts_as_list'
gem 'awesome_nested_set'
# gem 'acts_as_tree'
gem 'simple_form'
gem 'cocoon'
gem 'paperclip'
gem 'enumerize'
# gem 'paper_trail'
gem 'thin'
gem 'nokogiri'
gem 'turbolinks'
gem 'devise'


# Reporting
# gem 'thinreports-rails'
# jasper_rails need rjb which need $ sudo apt-get install openjdk-7-jdk and set JAVA_HOME and add a line in environement.rb
gem 'rjb'
gem 'jasper-rails', :git => 'git://github.com/fortesinformatica/jasper-rails.git'


gem 'jquery-rails'
#gem 'jquery_mobile_rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'oily_png'
  gem 'compass-rails'
  gem 'zurb-foundation'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'libv8', '~> 3.11.8'
  gem 'therubyracer', :platform => :ruby # , '~> 0.10.2'

  gem 'uglifier', '>= 1.0.3'
end


group :test do
  gem 'capybara'
  gem 'rspec-rails'
  gem 'cucumber-rails', :require => false
  # database_cleaner is not required, but highly recommended
  gem 'database_cleaner'
end

group :development do
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'quiet_assets'
end
