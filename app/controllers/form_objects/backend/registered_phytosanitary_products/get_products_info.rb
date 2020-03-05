module FormObjects
  module Backend
    module RegisteredPhytosanitaryProducts
      class GetProductsInfo < FormObjects::Base
        class << self
          # @return [GetProductsInfo]
          def from_params(params)
            new(params.permit(
              target_ids: [],
              products_and_usages_ids: %i[product_id usage_id]
            ))
          end
        end

        attr_accessor :target_ids, :products_and_usages_ids

        def targets
          @targets ||= [Plant, LandParcel].map { |s| s.where(id: target_ids) }.sum
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