module Calculus
  module ManureManagementPlan

    autoload :External,            'calculus/manure_management_plan/external'
    autoload :PoitouCharentes2013, 'calculus/manure_management_plan/poitou_charentes_2013'

    class << self

      # Redirect methods on given method
      def method_missing(method_name, *args)
        return "Calculus::ManureManagementPlan::#{options[:method].name.to_s.camelize}".constantize.send(method_name, *args)        
      end

    end

  end
end
