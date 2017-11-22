class PurchaseItemDecorator < Draper::Decorator
  delegate_all

  def amount_including_taxes
    (amount * (1 + (object.tax.amount / 100)).to_f).to_f
  end

  def merchandise_current_stock
    return 0 if object.variant.nil?

    object.variant.current_stock
  end

  def merchandise_stock_after_order
    return 0 if object.quantity.nil?

    merchandise_current_stock + object.quantity
  end

  def merchandise_stock_unit
    return '' if object.variant.nil?

    object.variant.unit_name
  end
end
