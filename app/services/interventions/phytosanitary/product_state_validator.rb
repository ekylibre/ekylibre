module Interventions
  module Phytosanitary
    class ProductStateValidator < ProductApplicationValidator

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        products_usages.each do |pu|
          phyto = pu.product.variant.phytosanitary_product

          if (pu.usage.present? && pu.usage.state == 'Retrait') || (phyto.present? && phyto.state == 'Retiré')
            # TODO: translate
            result.add_message(pu.product, 'Ce produit est retiré')
          end
        end

        result
      end
    end
  end
end