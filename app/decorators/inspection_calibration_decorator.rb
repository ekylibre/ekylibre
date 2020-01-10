class InspectionCalibrationDecorator < Draper::Decorator
  delegate_all

  def real_quantity(dimension)
    quantity = object.marketable_yield(dimension)

    unit = object.user_per_area_unit(dimension) if %i[surface_area_density mass_area_density].include? quantity.dimension
    unit = object.user_quantity_unit(dimension) if %i[none mass].include? quantity.dimension

    quantity.to_d(unit)
  end

  def product_available_area
    object.product.decorate.available_area
  end

  def net_stock(dimension)
    real_quantity(dimension).to_f * product_available_area.to_f
  end
end
