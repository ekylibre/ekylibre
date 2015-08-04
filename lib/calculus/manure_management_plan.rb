module Calculus
  module ManureManagementPlan
    # autoload :Aquitaine2013,       'calculus/manure_management_plan/aquitaine_2013'
    # autoload :External,            'calculus/manure_management_plan/external'
    # autoload :Method,              'calculus/manure_management_plan/method'
    # autoload :PoitouCharentes2013, 'calculus/manure_management_plan/poitou_charentes_2013'

    class << self
      def estimate_expected_yield(options = {})
        find_method(options).estimate_expected_yield
      end

      def compute(options = {})
        find_method(options).compute
      end

      def find_method(options)
        Calculus::ManureManagementPlan.const_get(options[:method].name.to_s.camelize).new(options)
      end
    end
  end
end

require 'calculus/manure_management_plan/method'
require 'calculus/manure_management_plan/external'
require 'calculus/manure_management_plan/poitou_charentes_2013'
require 'calculus/manure_management_plan/aquitaine_2013'
