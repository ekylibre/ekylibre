module Interventions
  module Phytosanitary
    module Models
      class ProductWithUsage

        class << self
          # @return [ProductWithUsage]
          def from_intervention_input(intervention_input)
            product = Product.find(intervention_input.product_id)
            phyto = RegisteredPhytosanitaryProduct.find_by(france_maaid: intervention_input.variant.france_maaid)
            usage = RegisteredPhytosanitaryUsage.find(intervention_input.usage_id)
            quantity = intervention_input.quantity_value
            dimension = intervention_input.quantity_unit_name

            new(product, phyto, usage, quantity, dimension)
          end

          # @return [Array<ProductWithUsage>]
          def from_intervention(intervention)
            intervention.inputs.map do |input|
              from_intervention_input(input)
            end
          end
        end

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
