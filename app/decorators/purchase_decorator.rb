class PurchaseDecorator < Draper::Decorator
  delegate_all

  def total_amount_excluding_taxes
    return 0 unless object.items.any?

    decorate_items.map(&:pretax_amount).sum
  end

  def total_amount_including_taxes
    return 0 unless object.items.any?

    total_amount_excluding_taxes + total_vat_amount
  end

  def total_vat_amount
    return 0 unless object.items.any?

    decorate_items.map do |item|
      if item.tax.nil? || item.tax.intracommunity
        0
      else
        item.pretax_amount * item.tax.amount / 100
      end
    end.sum
  end

  private

    def decorate_items
      PurchaseItemDecorator.decorate_collection(object.items)
    end
end
