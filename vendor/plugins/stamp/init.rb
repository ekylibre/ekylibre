require 'userstamp'
require 'migration'

ActiveRecord::Base.send(:include, Stamp::Userstamp)
ActiveRecord::Schema.send(:include, Stamp::Schema)
ActiveRecord::Migration.send(:include, Stamp::Migration)
