class ParcelItemStoringDecorator < Draper::Decorator
  delegate_all

  def merchandise_stock_after_reception(variant_quantity)
    variant_quantity + (quantity || 0)
  end

  def merchandise_stock_unit(variant_unit)
    variant_unit
  end
end
