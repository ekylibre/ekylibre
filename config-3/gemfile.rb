source 'http://rubygems.org'

gem 'rake', '0.8.7'
gem 'rails', '3.1.0.rc1'
# gem "i18n", ">= 0.5"
gem 'haml'
# Needed to use RJS
gem 'prototype-rails', :git => 'git://github.com/rails/prototype-rails.git'
gem 'fastercsv', :platforms=>[:ruby_18, :mri_18, :mingw_18, :mswin]
gem 'libxml-ruby', '1.1.3', :require=>'libxml'
gem 'rubyzip', :require=>'zip/zip'
gem 'will_paginate', '~> 3.0.pre2'
gem 'state_machine', :path => 'vendor/ogems/state_machine-0.9.4'
# gem 'ruby-graphviz', '>= 0.9.0'
gem 'exception_notification', :path => 'vendor/ogems/exception_notification-1.0.0', :require=>'exception_notifier'

# gem 'ruby-debug'


# Asset template engines
gem 'json'
gem 'sass'
gem 'coffee-script'
gem 'uglifier'

gem 'jquery-rails'


group :test do
  gem 'thoughtbot-shoulda', :require => 'shoulda'
end  

# gem 'sqlite3'
gem 'pg' # , '0.9.0'
gem 'mysql'
# gem 'activerecord-sqlserver-adapter', :path => 'vendor/ogems/activerecord-sqlserver-adapter-3.0.3'
# gem 'ruby-odbc'

