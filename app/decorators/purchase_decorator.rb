class PurchaseDecorator < Draper::Decorator
  delegate_all

  def total_amount_excluding_taxes
    return 0 unless object.items.any?

    decorate_items.map(&:pretax_amount).inject(0, :+)
  end

  def total_amount_including_taxes
    return 0 unless object.items.any?

    decorate_items.map(&:amount).inject(0, :+)
  end

  def total_vat_amount
    return 0 unless object.items.any?

    total_amount_including_taxes - total_amount_excluding_taxes
  end

  private

  def decorate_items
    PurchaseItemDecorator.decorate_collection(object.items)
  end
end
