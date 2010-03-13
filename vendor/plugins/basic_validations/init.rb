require 'basic_validations' unless defined?(Ekylibre::BasicValidations)
ActiveRecord::Base.send(:include, Ekylibre::BasicValidations::ActiveRecord::Base)
