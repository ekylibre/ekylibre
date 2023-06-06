# frozen_string_literal: true

class ConditioningValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if !record.variant || !record.unit || record.of_dimension?(:none)

    indicator = Unit::STOCK_INDICATOR_PER_DIMENSION[record.dimension.to_sym]

    return if record.variant.of_variety?(:equipment) && record.of_dimension?(:time) || # Equipment in duration
      record.variant.of_variety?(:equipment) && record.of_dimension?(:surface_area) || # Equipment in Ha
      record.variant.of_variety?(:worker) && record.of_dimension?(:time) || # Worker in duration
      record.dimension == record.variant.dimension || # Record and its variant belong to the same dimension unit wise
      record.variant.has_indicator?(indicator.to_sym) && record.variant.send(indicator).to_f > 0 # Variant has relevant indicator to perform conversions

    record.errors.add(attribute, :invalid_conditioning_dimension, variant_dimension: record.variant.dimension.l,
                                                                  conditioning_dimension: record.dimension.l,
                                                                  indicator_name: Onoma::Indicator.find(indicator).human_name)
  end
end
