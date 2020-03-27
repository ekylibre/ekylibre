module Interventions
  module Phytosanitary
    class AquaticBufferValidator < ProductApplicationValidator

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new
        return result if products_usages.length == 1

        products_usages
          .select { |prod_usage| prod_usage.usage.present? && prod_usage.usage.untreated_buffer_aquatic.present? && prod_usage.usage.untreated_buffer_aquatic >= 100 }
          .each do |prod_usage|
            usage = prod_usage.usage
            product = prod_usage.product
            message = :substances_mixing_not_allowed_due_to_znt_buffer.tl(usage: usage.crop_label_fra, phyto: product.name)

            result = result.merge(declare_forbidden_mix(product, with: products_usages.map(&:product), message: message))
            result.vote_forbidden(product, message)
          end

        result
      end
    end
  end
end
