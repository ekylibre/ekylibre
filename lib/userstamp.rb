module Userstamp
  autoload :Stamper,         'userstamp/stamper'
  autoload :Stampable,       'userstamp/stampable'
  autoload :Controller,      'userstamp/controller'
  autoload :MigrationHelper, 'userstamp/migration_helper'
end

ActionController::Base.send(:include, Userstamp::Controller)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Userstamp::MigrationHelper)
