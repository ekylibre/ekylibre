source :gemcutter

# gem "ruby-debug"

gem "rake", "0.8.7"
gem "rails", "2.3.10"
gem "i18n", ">= 0.5"
gem "haml"
gem "fastercsv", :platforms=>[:ruby_18, :mri_18, :mingw_18, :mswin]
gem "libxml-ruby", "1.1.3", :require=>"libxml"
gem "rubyzip", :require=>"zip/zip"
gem "will_paginate", "~> 2.3"
gem "exception_notification", :branch=>"2-3-stable", :git=>"https://github.com/smartinez87/exception_notification.git" # , :require=>"exception_notifier"

gem "state_machine", "0.9.4"
# gem "ruby-graphviz", ">= 0.9.0"

group :test do
  gem "shoulda"
end  

gem "pg", "0.11.0"
gem "mysql"
gem "sqlite3"
