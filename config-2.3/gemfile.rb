source :gemcutter

# gem "ruby-debug"

# gem "rake", "0.8.7"
gem "rails", "2.3.10"
gem "i18n", ">= 0.5"
gem "haml"
gem "fastercsv" # , :platforms=>[:ruby_18, :mri_18, :mingw_18, :mswin]
gem "libxml-ruby", "1.1.3", :require=>"libxml"
gem "rubyzip", :require=>"zip/zip"
gem "will_paginate", "~> 2.3"
# gem "exception_notification", :branch=>"2-3-stable", :git=>"https://github.com/smartinez87/exception_notification.git" # , :require=>"exception_notifier"
gem "exception_notification", :path => "vendor/ogems/exception_notification-2.3.3.0"

# gem "formtastic", "1.2.4"
# gem "simple_form", "1.0.4"
# gem "formize", :path => "vendor/ogems/formize"
gem "formize"

gem "state_machine", "0.9.4"
# gem "ruby-graphviz", ">= 0.9.0"

group :test do
  gem "shoulda"
  gem "ruby-prof"
end  

platform :mswin do
  gem "thin", ">= 1.2.6"
end

gem "pg", "0.11.0"
gem "mysql"
gem "sqlite3"
