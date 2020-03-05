module Interventions
  module Phytosanitary
    class MixCategoryCodeValidator < ProductApplicationValidator
      def has_category_code(phyto)
        %w[2 3 4 5].include?(phyto.mix_category_code)
      end

      def mix_code(product)
        product.variant.phytosanitary_product.mix_category_code
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        ## Valid
        return Models::ProductApplicationResult.new if products_usages.length == 1
        products = products_usages.map(&:product)

        # Mix code == 5
        mix5result = Result.new
        mix5 = products.select { |p| mix_code(p) == '5' }
        mix5.each do |product|
          mix5result.add_message(product, :cannot_be_mixed_with_any_product.tl)

          mix5result = mix5result.merge(declare_forbidden_mix(product, with: products, message: :cannot_be_mixed_with.tl(phyto: product.name)))
        end

        # Other forbidden mixes
        p_by_code = products.group_by { |p| mix_code(p) }.slice('2', '3', '4')

        # mix_results: Result[]
        mix_results = p_by_code.flat_map do |_code, prods|
          if prods.length > 1
            prods.map { |p| declare_forbidden_mix(p, with: prods, message: :cannot_be_mixed_with.tl(phyto: product.name)) }
          else
            [Models::ProductApplicationResult.new]
          end
        end

        mix5result.merge_all(mix_results)
      end
    end
  end
end