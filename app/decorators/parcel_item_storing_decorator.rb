class ParcelItemStoringDecorator < Draper::Decorator
  delegate_all

  def merchandise_stock_after_reception(variant_quantity)
    quantity ||= 0
    variant_quantity + quantity
  end

  def merchandise_stock_unit(variant_unit)
    variant_unit
  end
end
