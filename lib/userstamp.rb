module Userstamp
  autoload :Stamper,         'userstamp/stamper'
  autoload :Stampable,       'userstamp/stampable'
  autoload :Controller,      'userstamp/controller'
  autoload :MigrationHelper, 'userstamp/migration_helper'
end

ActiveRecord::Base.send(:include, Userstamp::Stamper)
ActiveRecord::Base.send(:include, Userstamp::Stampable)
ActionController::Base.send(:include, Userstamp::Controller)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Userstamp::MigrationHelper)
