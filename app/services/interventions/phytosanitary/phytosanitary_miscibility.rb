module Interventions
  module Phytosanitary
    # This object describes the mixing of phyto products.
    class PhytosanitaryMiscibility
      def initialize(products_and_variants)
        @variants = products_and_variants.map do |prod_or_var|
          next prod_or_var unless prod_or_var.respond_to?(:variant)
          product = prod_or_var
          product.variant
        end
      end

      def valid?
        validity == :valid
      end

      def validity
        mixtures = @variants.combination(2).flat_map do |first, second|
          first_risks = self.class.risk_groups_of(first)
          second_risks = self.class.risk_groups_of(second)

          pairs_of_levels = first_risks.product(second_risks)
          pairs_of_levels.map { |group1, group2| self.class.mix_of(group1, group2) }
        end

        incomplete = mixtures.include? ::Phytosanitary::Mixture::Incomplete
        present_mixtures = mixtures - [::Phytosanitary::Mixture::Incomplete]

        valid = present_mixtures.all?(&:allowed)

        return :invalid unless valid
        return :incomplete if incomplete
        :valid
      end

      def self.mix_of(first_group, second_group)
        ::Pesticide::AllowedMixtureAbacus.find_mixture(first_group, second_group)
      end

      def self.risk_groups_of(variant)
        variant_risk = ::Phytosanitary::Risk.risks_of(variant)
        variant_risk.flat_map(&:group).uniq
      end
    end
  end
end