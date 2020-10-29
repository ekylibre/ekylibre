module FormObjects
  module Backend
    module RegisteredPhytosanitaryProducts
      class GetProductsInfo < FormObjects::Base
        class << self
          # @return [GetProductsInfo]
          def from_params(params)
            new(params.permit(
              targets_data: %i[id shape],
              products_data: %i[product_id usage_id quantity dimension]
            ))
          end
        end

        attr_accessor :targets_data, :products_data

        def targets_data
          @targets_data&.values || []
        end

        def products_data
          @products_data&.values || {}
        end

        def targets_and_shape
          @targets_and_shape ||= targets_data.flat_map do |data|
            target = [Plant, LandParcel].map { |model| model.find_by(id: data[:id]) }.compact.first
            shape = Charta::new_geometry(data[:shape])

            if target.present?
              [::Interventions::Phytosanitary::Models::TargetAndShape.new(target, shape)]
            else
              []
            end
          end
        end

        def targets_ids
          @targets_ids || []
        end

        def products_and_usages_ids
          @products_and_usages_ids || []
        end

        def targets
          targets_and_shape.map(&:target)
        end

        def products_and_usages
          @products_and_usages ||= products_data.map do |pu|
            product = Product.find_by(id: pu[:product_id])
            usage = RegisteredPhytosanitaryUsage.find_by(id: pu[:usage_id])
            quantity = pu[:quantity].to_f
            dimension = pu[:dimension]

            ::Interventions::Phytosanitary::Models::ProductWithUsage.new(product, usage, quantity, dimension)
          end.reject { |pu| pu.product.nil? }
        end
      end
    end
  end
end
