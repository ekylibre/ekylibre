module Interventions
  module Phytosanitary
    class MixCategoryCodeValidator < ProductApplicationValidator

      # @param [RegisteredPhytosanitaryProduct, InterventionParameter::LoggedPhytosanitaryProduct] phyto
      # @return [Array<Integer>]
      def mix_codes(phyto)
        phyto.present? ? phyto.mix_category_codes : []
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if products_usages.size > 1
          p_by_code = products_usages
                        .flat_map { |pu| mix_codes(pu.phyto).map { |code| [code, pu.product] } }
                        .group_by(&:first).transform_values { |a| a.map(&:second) }

          # Mix code == 5
          mix5result = Models::ProductApplicationResult.new
          mix5 = p_by_code.fetch(5, [])
          mix5.each do |product|
            mix5result.vote_forbidden(product, :cannot_be_mixed_with_any_product.tl)

            mix5result = mix5result.merge_all(*declare_forbidden_mix(product, with: products_usages.map(&:product), message: :cannot_be_mixed_with.tl(phyto: product.name)))
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
