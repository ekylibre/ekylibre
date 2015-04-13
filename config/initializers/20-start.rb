# Load all libs contained in lib/
require 'userstamp'
require 'migration_helper'

# Data types and core ext
require 'delay'
ActiveRecord::Base.send(:extend, Delay::Validation::ClassMethods)

require 'safe_string'
autoload :SymbolArray, 'symbol_array'

# Data exchanges
autoload :Exchanges, 'exchanges'

# App-specific libs
require 'ekylibre'

# XML definitions
autoload :Nomen,     'nomen'
autoload :Aggeratio, 'aggeratio'
autoload :Procedo,   'procedo'
# require 'nomen'
# require 'aggeratio'
# require 'procedo'

# Measure
require 'measure'
class ::Numeric
  eval(Measure.units.inject("") do |code, unit|
         code << "def in_#{unit}\n"
         code << "  Measure.new(self, :#{unit})\n"
         code << "end\n"
         code
       end)

  def in(unit)
    Measure.new(self, unit)
  end
end

# autoload :Calculus, 'calculus'

# Other things...
require 'reporting'
require 'enumerize/xml'

# require 'active_list'
# ::ActionController::Base.send(:include, ActiveList::ActionPack::ActionController)
# ::ActionView::Base.send(:include, ActiveList::ActionPack::ViewsHelper)

unless ENV["PLUGIN"] == "false"
  Ekylibre::Plugin.load
end
Ekylibre::Plugin.plug
