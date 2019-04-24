class ReceptionItemDecorator < Draper::Decorator
  delegate_all

  # def reception_number
  #   return '' if object.parcels_purchase_invoice_items.nil? || object.parcels_purchase_invoice_items.first.nil?

  #   reception_id = object.parcels_purchase_invoice_items.first.parcel_id

  #   Reception.find_by(id: reception_id)&.reference_number || ''
  # end

  def merchandise_stock_after_reception(variant_quantity)
    quantity ||= 0
    variant_quantity + quantity
  end

  def merchandise_stock_unit(variant_unit)
    variant_unit
  end
end
