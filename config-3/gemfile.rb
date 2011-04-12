source 'http://rubygems.org'

gem 'rails', '3.0.3'
gem "i18n", ">= 0.5"
gem 'haml'
gem 'fastercsv', :platforms=>[:ruby_18, :mri_18]
gem 'libxml-ruby', '1.1.3', :require=>'libxml'
gem 'rubyzip', :require=>'zip/zip'
gem 'will_paginate', '~> 3.0.pre2'
gem 'state_machine', :path => 'vendor/ogems/state_machine-0.9.4'
# gem 'ruby-graphviz', '>= 0.9.0'
gem 'exception_notification', :path => 'vendor/ogems/exception_notification-1.0.0', :require=>'exception_notifier'

# gem 'ruby-debug'

group :test do
  gem 'thoughtbot-shoulda', :require => 'shoulda'
end  

# gem 'sqlite3-ruby', :require => 'sqlite3', :platforms=>[:ruby_19, :mri_19]
gem 'pg', '0.9.0'
gem 'mysql'
gem 'activerecord-sqlserver-adapter', :path => 'vendor/ogems/activerecord-sqlserver-adapter-3.0.3'
# gem 'ruby-odbc'
