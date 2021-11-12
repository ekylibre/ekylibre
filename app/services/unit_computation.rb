# frozen_string_literal: true

class UnitComputation

  class << self
    # LUCAS_TODO: Add tests for these methods
    def convert_stock(quantity, from, to)
      quantity * coefficient(from, to)
    end

    def convert_seed_stock(quantity, from, to, variant)
      pmg = variant.thousand_grains_mass
      pmg_unit = Unit.import_from_lexicon(pmg.unit)
      unity_unit = Unit.import_from_lexicon('unity')
      if pmg.present? && pmg_unit.present? && pmg.positive?
        # convert from mass (ex 25 kg) to none (ex 50 milliers)
        if pmg_unit.dimension == from.dimension && to.dimension == 'none'
          unity_net_mass = convert_stock(pmg.value, pmg_unit, from) / 1000
          convert_stock((quantity / unity_net_mass).round(2), unity_unit, to)
        elsif from.dimension == 'none' && pmg_unit.dimension == to.dimension
          unity_net_mass = convert_stock(pmg.value, pmg_unit, to) / 1000
          convert_stock((quantity * unity_net_mass), from, unity_unit)
        elsif from.dimension == to.dimension && (to.dimension == 'mass' || to.dimension == 'none')
          convert_stock(quantity, from, to)
        else
          raise "The units provided #{from.name} and #{to.name} are not compatible to convert seed stock"
        end
      else
        raise 'thousand_grains_mass indicator is missing on variant'
      end
    end

    def convert_amount(amount, from, to)
      amount * coefficient(to, from)
    end

    def convert_into_variant_population(variant, quantity, from)
      indicator = variant.relevant_stock_indicator(from.dimension)
      indicator_unit = Unit.import_from_lexicon(indicator.unit)

      qty_in_indicator_unit = quantity * coefficient(from, indicator_unit)
      qty_in_indicator_unit / indicator.to_f
    end

    def convert_into_variant_unit(variant, quantity, from)
      qty_in_variant_population = convert_into_variant_population(variant, quantity, from)
      return qty_in_variant_population if variant.of_dimension?(:none)

      indicator = variant.relevant_stock_indicator(variant.dimension)
      qty_in_variant_population * (indicator.in(variant.default_unit_name).to_f / variant.default_quantity)
    end

    def coefficient(from, over)
      raise 'The units provided belong to different dimensions' if from.dimension != over.dimension

      from_factor = dimension_base_unit_factor(from)
      over_factor = dimension_base_unit_factor(over)

      from_factor / over_factor
    end

    def dimension_base_unit_factor(unit)
      dimension_base_unit = Unit.import_from_lexicon(Unit::BASE_UNIT_PER_DIMENSION[unit.dimension.to_sym])
      factor = unit.coefficient || 1

      until unit == dimension_base_unit
        unit = unit.base_unit
        factor *= unit.coefficient
      end

      factor
    end
  end
end
