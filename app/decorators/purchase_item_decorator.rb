class PurchaseItemDecorator < Draper::Decorator
  delegate_all

  def reception_number
    return '' if object.parcels_purchase_invoice_items.nil? || object.parcels_purchase_invoice_items.first.nil?

    reception_id = object.parcels_purchase_invoice_items.first.parcel_id

    Reception.find(reception_id).reference_number
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
