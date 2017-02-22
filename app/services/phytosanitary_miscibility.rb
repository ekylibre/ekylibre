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
    @variants.combination(2).all? do |first, second|
      self.class.miscible_variants?(first, second)
    end
  end

  def validity
    valid? ? :valid : :invalid
  end

  def self.miscible_variants?(first, second)
    pairs_of_levels = risk_groups_of(first)
                      .product(risk_groups_of(second))

    pairs_of_levels.all? { |group1, group2| allowed_mix?(group1, group2) }
  end

  def self.allowed_mix?(first_group, second_group)
    PesticideAllowedMixtureAbacus.mixture_allowed?(first_group, second_group)
  end

  def self.risk_groups_of(variant)
    variant_risk = PhytosanitaryRisk.risks_of(variant)
    variant_risk.flat_map(&:group).uniq
  end
end

# Represent a risks
class PhytosanitaryRisk
  attr_reader :code
  attr_reader :group

  def initialize(risk_level)
    @code  = risk_level.to_s
    @group = PesticideRisksGroupAbacus.find_group_of(@code) || PesticideRiskGroup[5]
  end

  def self.risks_of(variant)
    return [] unless maaid = variant.france_maaid
    risks = Pesticide::Agent.find(maaid).risks
    risks.map { |risk| new(risk) }
  end
end
