module Interventions
  module Phytosanitary
    class MixCategoryCodeValidator < ProductApplicationValidator

      # @param [Product] product
      # @return [Array<Integer>]
      def mix_codes(product)
        phyto = product.variant.phytosanitary_product
        if phyto.present?
          phyto.mix_category_codes
        else
          []
        end
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if products_usages.size > 1
          products = products_usages.map(&:product)

          p_by_code = products
                        .flat_map { |product| mix_codes(product).map { |code| [code, product] } }
                        .group_by(&:first).transform_values { |a| a.map(&:second) }

          # Mix code == 5
          mix5result = Models::ProductApplicationResult.new
          mix5 = p_by_code.fetch(5, [])
          mix5.each do |product|
            mix5result.vote_forbidden(product, :cannot_be_mixed_with_any_product.tl)

            mix5result = mix5result.merge(declare_forbidden_mix(product, with: products, message: :cannot_be_mixed_with.tl(phyto: product.name)))
          end

          # Other forbidden mixes
          mix_results = p_by_code.slice(2, 3, 4).values.flat_map do |prods|
            if prods.length > 1
              prods.map { |p| declare_forbidden_mix(p, with: prods, message: :cannot_be_mixed_with.tl(phyto: p.name)) }
            else
              [Models::ProductApplicationResult.new]
            end
          end

          result = result.merge_all(mix5result, *mix_results)
        end

        result
      end
    end
  end
end
