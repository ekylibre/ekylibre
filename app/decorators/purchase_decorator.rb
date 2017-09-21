class PurchaseDecorator < Draper::Decorator
  delegate_all

  def total_amount_excluding_taxes
    return 0 unless object.items.any?

    decorate_items.map(&:amount_excluding_taxes).inject(0, :+)
  end

  def total_amount_including_taxes
    return 0 unless object.items.any?

    decorate_items.map(&:amount_including_taxes).inject(0, :+)
  end

  def total_vat_amount
    return 0 unless object.items.any?

    object
      .items
      .map(&:tax)
      .map(&:amount)
      .inject(0, :+)
  end

  private

  def decorate_items
    PurchaseItemDecorator.decorate_collection(object.items)
  end
end
