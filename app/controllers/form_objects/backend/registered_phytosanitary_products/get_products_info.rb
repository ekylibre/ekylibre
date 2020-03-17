module FormObjects
  module Backend
    module RegisteredPhytosanitaryProducts
      class GetProductsInfo < FormObjects::Base
        class << self
          # @return [GetProductsInfo]
          def from_params(params)
            new(params.permit(
              targets_ids: [],
              products_and_usages_ids: %i[product_id usage_id]
            ))
          end
        end

        attr_accessor :targets_ids, :products_and_usages_ids

        def targets_ids
          @targets_ids || []
        end

        def products_and_usages_ids
          @products_and_usages_ids || {}
        end

        def targets
          @targets ||= [Plant, LandParcel].map { |s| s.where(id: targets_ids) }.sum
        end

        def products_and_usages
          @products_and_usages ||= products_and_usages_ids.values.map do |pu|
            product = Product.find_by(id: pu[:product_id])
            usage = RegisteredPhytosanitaryUsage.find_by(id: pu[:usage_id])

            ::Interventions::Phytosanitary::Models::ProductWithUsage.new(product, usage)
          end
        end
      end
    end
  end
end
