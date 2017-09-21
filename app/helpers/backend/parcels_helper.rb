module Backend::ParcelsHelper

  def purchase_item_pretax_amount(item)
    if item.unit_pretax_amount.present? && item.unit_pretax_amount > 0
      return item.unit_pretax_amount
    elsif item.purchase_item.present?
      item.purchase_item.unit_pretax_amount
    else
      nil
    end
  end
end
