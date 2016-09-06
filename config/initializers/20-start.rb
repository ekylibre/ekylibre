# Load all libs contained in lib/
require 'userstamp'
require 'migration_helper'

# Data types and core ext
require 'delay'
ActiveRecord::Base.send(:extend, Delay::Validation::ClassMethods)

require 'safe_string'
autoload :SymbolArray, 'symbol_array'

# ActionIntegration
autoload :ActionIntegration, 'action_integration'

# ActiveThing
autoload :ActiveExchanger, 'active_exchanger'
autoload :ActiveGuide,     'active_guide'
autoload :ActiveSensor,    'active_sensor'

# App-specific libs
require 'ekylibre'

require 'working_set'

# XML definitions
autoload :Nomen,     'nomen'
autoload :Aggeratio, 'aggeratio'
# autoload :Procedo,   'procedo'
# require 'nomen'
# require 'aggeratio'
# require 'procedo'

# Measure
require 'measure'
class ::Numeric
  Measure.units.each do |unit|
    define_method "in_#{unit}".to_sym do
      Measure.new(self, unit)
    end
  end

  def in(unit)
    Measure.new(self, unit)
  end
end

# autoload :Calculus, 'calculus'

# Other things...
require 'reporting'
require 'enumerize/xml'
require 'state_machine/i18n'

require 'open_weather_map' if Nomen[:indicators]

# require 'active_list'
# ::ActionController::Base.send(:include, ActiveList::ActionPack::ActionController)
# ::ActionView::Base.send(:include, ActiveList::ActionPack::ViewsHelper)

Ekylibre.load_integrations

Ekylibre::Plugin.load unless ENV['PLUGIN'] == 'false'
Ekylibre::Plugin.plug

Aggeratio.load_path += Dir.glob(Rails.root.join('config', 'aggregators', '**', '*.xml'))
Aggeratio.load

# MapBackgrounds
autoload :MapBackgrounds, 'map_backgrounds'
MapBackgrounds::Layer.load
