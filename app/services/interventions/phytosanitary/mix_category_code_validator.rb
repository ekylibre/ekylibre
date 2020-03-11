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
        ## Valid
        return Models::ProductApplicationResult.new if products_usages.length == 1
        products = products_usages.map(&:product)

        p_by_code = products.flat_map do |product|
          mix_codes(product).map { |code| [code, product] }
        end

        p_by_code = p_by_code.group_by(&:first).transform_values { |a| a.map(&:second) }

        # Mix code == 5
        mix5result = Models::ProductApplicationResult.new
        mix5 = p_by_code.fetch(5, [])
        mix5.each do |product|
          mix5result.add_message(product, :cannot_be_mixed_with_any_product.tl)

          mix5result = mix5result.merge(declare_forbidden_mix(product, with: products, message: :cannot_be_mixed_with.tl(phyto: product.name)))
        end

        # Other forbidden mixes
        other_codes = p_by_code.slice(2, 3, 4)

        # mix_results: Result[]
        mix_results = other_codes.flat_map do |_code, prods|
          if prods.length > 1
            prods.map { |p| declare_forbidden_mix(p, with: prods, message: :cannot_be_mixed_with.tl(phyto: p.name)) }
          else
            [Models::ProductApplicationResult.new]
          end
        end

        mix5result.merge_all(*mix_results)
      end
    end
  end
end
