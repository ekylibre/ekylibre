class InspectionCalibrationDecorator < Draper::Decorator
  delegate_all

  def real_quantity(dimension)
    quantity = object.marketable_quantity(dimension)

    unit = object.user_per_area_unit(dimension) if %i[surface_area_density mass_area_density].include? quantity.dimension
    unit = object.user_quantity_unit(dimension) if %i[none mass].include? quantity.dimension

    quantity.to_d(unit)
  end
end
