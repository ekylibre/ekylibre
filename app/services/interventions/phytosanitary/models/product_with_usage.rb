module Interventions
  module Phytosanitary
    module Models
      class ProductWithUsage
        attr_reader :product, :phyto, :usage, :quantity, :dimension

        # @param [Product] product
        # @param [RegisteredPhytosanitaryProduct, InterventionParameter::LoggedPhytosanitaryProduct] phyto
        # @param [RegisteredPhytosanitaryUsage, InterventionParameter::LoggedPhytosanitaryUsage] usage
        # @param [Numeric] quantity
        # @param [String] dimension
        def initialize(product, phyto, usage, quantity, dimension)
          @product = product
          @phyto = phyto
          @usage = usage
          @quantity = quantity
          @dimension = dimension
        end
      end
    end
  end
end
