module Dimensionable
  extend ActiveSupport::Concern

  def of_dimension?(dimension)
    dose_unit.present? && Nomen::Unit.find(dose_unit).dimension == dimension.to_sym
  end

  def among_dimensions?(*dimensions)
    dimensions.any? { |dimension| of_dimension?(dimension) }
  end
end
