require File.join(File.dirname(__FILE__), 'ekylibre', 'record')
require File.join(File.dirname(__FILE__), 'ekylibre', 'models')
require File.join(File.dirname(__FILE__), 'ekylibre', 'sqlserver_date_support')
require File.join(File.dirname(__FILE__), 'ekylibre', 'export')
require File.join(File.dirname(__FILE__), 'ekylibre', 'menus')
require File.join(File.dirname(__FILE__), 'ekylibre', 'routes')
require File.join(File.dirname(__FILE__), 'ekylibre', 'backup')

module Ekylibre
  mattr_reader :model_names
  @@model_names = @@models.collect{|m| m.to_s.camelcase.to_sym}.sort.freeze
end
