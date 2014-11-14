require 'calculus/manure_management_plan/method'

module Calculus
  module ManureManagementPlan

    # This method considers that values are not computed here so it does quite nothing
    class External < Method

      # Cannot estimate without any method, so zero...
      def estimate_expected_yield
        return 0.0.in_quintal_per_hectare
      end

      # Compute nothing...
      def compute
        return @options
      end

    end

  end
end
