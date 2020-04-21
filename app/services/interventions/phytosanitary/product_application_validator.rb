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

        # @param [Product] product
        # @return [Array<Intervention>]
        def get_interventions_with_same_phyto(product, current_campaign)
          Intervention.of_campaigns(*[current_campaign, current_campaign.previous, current_campaign.following].compact)
                      .of_nature_using_phytosanitary
                      .with_input_of_maaids(product.france_maaid)
        end

        # @param [Array<Intervention>] interventions
        # @param [Array<Charta::Geometry>] zones
        # @return [Array<Intervention>]
        def select_with_shape_intersecting(interventions, zones)
          interventions.select do |intervention|
            intervention.targets.map(&:working_zone).any? { |wz| zones.any? { |shape| shape.intersects?(wz) } }
          end
        end
    end
  end
end