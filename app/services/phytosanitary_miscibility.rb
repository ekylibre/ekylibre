# This object describes the mixing of phyto products.
class PhytosanitaryMiscibility
  def initialize(products_and_variants)
    @variants = products_and_variants.map do |prod_or_var|
      if prod_or_var.respond_to?(:variant)
        product = prod_or_var
        product.variant
      else
        prod_or_var # <- variant
      end
    end
  end

  def legality
    return :valid
    @variants.combination(2).all? do |first, second|
      self.class.miscible_variants?(first, second)
    end
  end

  def self.miscible_variants?(first, second)
    pairs_of_levels = risk_groups_of(first)
                      .product(risk_groups_of(second))

    pairs_of_levels.all? { |group1, group2| allowed_mix?(group1, group2) }
  end

  def self.allowed_mix?(first_group, second_group)
    true if first_group && second_group # CHECK FROM CSV I GUESS?
  end

  def self.risk_groups_of(variant)
    variant_risk = PhytosanitaryRisk.risks_of(variant)
    variant_risk.flat_map(&:group)
  end
end

# Represent a risks
class PhytosanitaryRisk
  attr_reader :code
  attr_reader :group

  def initialize(risk_level)
    @code  = risk_level.to_s
    @group = PesticideRisksGroupAbacus.find_group_of(@code)
  end

  def self.risks_of(variant)
    return [] unless maaid = variant.france_maaid
    risks = Pesticide::Agent.find(maaid).risks
    risks.map { |risk| new(risk) }
  end
end
