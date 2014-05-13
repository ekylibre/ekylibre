module Calculus
  module ManureManagementPlan

    autoload :Method,              'calculus/manure_management_plan/method'
    autoload :External,            'calculus/manure_management_plan/external'
    autoload :PoitouCharentes2013, 'calculus/manure_management_plan/poitou_charentes_2013'
    autoload :Aquitaine2013, 'calculus/manure_management_plan/aquitaine_2013'
    
    class << self

      def estimate_expected_yield(options = {})
        return find_method(options).estimate_expected_yield
      end

      def compute(options = {})
        return find_method(options).compute
      end

      def find_method(options)
        "Calculus::ManureManagementPlan::#{options[:method].name.to_s.camelize}".constantize.new(options)
      end

    end

  end
end
