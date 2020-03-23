module Interventions
  module Phytosanitary
    class ProductApplicationValidator

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        raise NotImplementedError
      end

      protected

        def other_products(products, product)
          products.reject { |p| p == product }
        end

        # @param [Product] product
        # @option [Array<Product>] with
        # @return [Models::ProductApplicationResult]
        def declare_forbidden_mix(product, with: [], message:)
          result = Models::ProductApplicationResult.new

          other_products(with, product).each do |p|
            result.vote_forbidden(p, message)
          end

          result
        end
    end
  end
end