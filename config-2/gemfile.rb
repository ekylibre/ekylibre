source :gemcutter # "http://rubygems.org"

gem "rails", "2.3.10"
gem "i18n", ">= 0.5"
gem "haml"
gem "fastercsv", :platforms=>[:ruby_18, :mri_18, :mingw_18, :mswin]
gem "libxml-ruby", "1.1.3", :require=>"libxml"
gem "rubyzip", :require=>"zip/zip"
gem "will_paginate", "~> 2.3"
gem "state_machine", :path => "vendor/ogems/state_machine-0.9.4"
# gem "ruby-graphviz", ">= 0.9.0"
# gem "exception_notification", :path => "vendor/ogems/exception_notification-2.3.3.0", :require=>"exception_notifier"

# gem "ruby-debug"

group :test do
  gem "shoulda" # , "2.10.3", :require => "shoulda"
end  

# gem "sqlite3-ruby", :require => "sqlite3", :platforms=>[:ruby_19, :mri_19]
gem "pg", "0.9.0"
gem "mysql"
gem "sqlite3"
