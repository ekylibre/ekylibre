# frozen_string_literal: true

class UnitComputation

  class << self
    # LUCAS_TODO: Add tests for these methods
    def convert_stock(quantity, from, to)
      quantity * coefficient(from, to)
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
      qty_in_variant_population * indicator.in(variant.default_unit_name).to_f
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
