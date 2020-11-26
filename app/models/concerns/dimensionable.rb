module Dimensionable
  extend ActiveSupport::Concern

  def of_dimension?(dimension)
    dose_unit.present? && Onoma::Unit.find(dose_unit).dimension == dimension.to_sym
  end

  def among_dimensions?(*dimensions)
    dimensions.any? { |dimension| of_dimension?(dimension) }
  end
end
