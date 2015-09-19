# Load all libs contained in lib/
require 'userstamp'
require 'migration_helper'

# Data types and core ext
require 'delay'
ActiveRecord::Base.send(:extend, Delay::Validation::ClassMethods)

require 'safe_string'
autoload :SymbolArray, 'symbol_array'

# ActiveThing
autoload :ActiveExchanger, 'active_exchanger'
autoload :ActiveGuide,     'active_guide'
autoload :ActiveSensor,    'active_sensor'

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
  eval(Measure.units.inject('') do |code, unit|
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
require 'state_machine/i18n'

if Nomen[:indicators]
  require 'open_weather_map'
end

# require 'active_list'
# ::ActionController::Base.send(:include, ActiveList::ActionPack::ActionController)
# ::ActionView::Base.send(:include, ActiveList::ActionPack::ViewsHelper)

Ekylibre::Plugin.load unless ENV['PLUGIN'] == 'false'
Ekylibre::Plugin.plug

Aggeratio.load_path += Dir.glob(Rails.root.join('config', 'aggregators', '**', '*.xml'))
Aggeratio.load
