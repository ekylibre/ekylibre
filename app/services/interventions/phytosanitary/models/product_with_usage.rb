module Interventions
  module Phytosanitary
    module Models
      class ProductWithUsage
        attr_reader :product, :usage, :quantity, :dimension

        # @param [Product] product
        # @param [RegisteredPhytosanitaryUsage] usage
        def initialize(product, usage, quantity, dimension)
          @product = product
          @usage = usage
          @quantity = quantity
          @dimension = dimension
        end
      end
    end
  end
end