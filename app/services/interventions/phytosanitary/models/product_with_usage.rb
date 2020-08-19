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
            measure = Measure.new(intervention_input.quantity_value, intervention_input.quantity_unit_name)
            spray_volume = intervention_input.spray_volume

            new(product, phyto, usage, measure, spray_volume)
          end

          # @return [Array<ProductWithUsage>]
          def from_intervention(intervention)
            intervention.inputs.map do |input|
              from_intervention_input(input)
            end
          end
        end

        attr_reader :product, :phyto, :usage, :measure, :spray_volume

        # @param [Product] product
        # @param [RegisteredPhytosanitaryProduct, InterventionParameter::LoggedPhytosanitaryProduct] phyto
        # @param [RegisteredPhytosanitaryUsage, InterventionParameter::LoggedPhytosanitaryUsage] usage
        # @param [Measure] measure
        # @param [BigDecimal, nil] spray_volume
        def initialize(product, phyto, usage, measure, spray_volume)
          @product = product
          @phyto = phyto
          @usage = usage
          @measure = measure
          @spray_volume = spray_volume
        end

        # @return [Numeric]
        def quantity
          ActiveSupport::Deprecation.warn "ProductWithUsage#quantity is deprecated; use the measure instead"

          measure.value
        end

        # @return [String]
        def dimension
          ActiveSupport::Deprecation.warn "ProductWithUsage#dimension is deprecated; use the measure instead"

          case measure.dimension
          when 'volume_concentration'
            'volume_density'
          when 'mass_concentration'
            'specific_weight'
          else
            measure.dimension
          end
        end
      end
    end
  end
end
