source :gemcutter

# gem 'ruby-debug'

gem 'rake', '0.8.7'
gem 'rails', '3.0.9'
gem 'haml'
gem 'fastercsv', :platforms=>[:ruby_18, :mri_18, :mingw_18, :mswin]
gem 'libxml-ruby', :require=>'libxml' # , '1.1.3'
gem 'rubyzip', :require=>'zip/zip'
gem 'will_paginate', '~> 3.0.pre2'
gem "exception_notification" # , :branch=>"master", :git=>"https://github.com/smartinez87/exception_notification.git", :require=>"exception_notifier"

gem 'state_machine', "0.9.4"
# gem 'ruby-graphviz', '>= 0.9.0'

# Needed to use RJS with Rails ~> 3.1
# gem 'prototype-rails', :git => 'git://github.com/rails/prototype-rails.git'
# gem 'jquery-rails'

# Asset template engines
gem 'json'
gem 'sass'
gem 'coffee-script'
gem 'uglifier'

group :test do
  gem 'thoughtbot-shoulda', :require => 'shoulda'
end  

gem 'pg', '0.11.0'
gem 'mysql'
gem 'sqlite3'

