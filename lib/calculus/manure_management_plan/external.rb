module Calculus
  module ManureManagementPlan
    
    # This method considers that values are not computed here so it does quite nothing
    module External
      
      class << self

        # Cannot estimate without any method, so zero...
        def estimate_expected_yield(options = {})
          return 0.0.in_quintal_per_hectare
        end

        # Compute nothing...
        def compute(options = {})
          return {}
        end
        
      end

    end

  end
end
