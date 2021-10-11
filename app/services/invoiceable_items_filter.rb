# frozen_string_literal: true

class InvoiceableItemsFilter
  def filter(receptions)
    receptions.flat_map do |reception|
      reception.items.where(purchase_invoice_item_id: nil).flat_map do |item|
        invoice_item_attributes = {
          variant_id: item.variant_id,
          purchase_id: item.parcel_id,
          currency: item.currency,
          unit_pretax_amount: item.unit_pretax_amount,
          pretax_amount: item.pretax_amount,
          role: item.role,
          conditioning_quantity: item.conditioning_quantity,
          conditioning_unit_id: item.conditioning_unit_id,
          tax_id: item.purchase_order_item&.tax_id,
          activity_budget_id: item.activity_budget_id,
          project_budget_id: item.project_budget_id,
          team_id: item.team_id,
          equipment_id: item.equipment_id,
          annotation: item.annotation,
          parcels_purchase_invoice_items: [item]
        }

        if item.storings.any?
          item.storings.group_by(&:conditioning_unit_id).map do |unit_id, storings|
            PurchaseItem.new(invoice_item_attributes.merge(conditioning_quantity: storings.map(&:conditioning_quantity).sum, conditioning_unit_id: unit_id))
          end
        else
          PurchaseItem.new(invoice_item_attributes)
        end
      end
    end.compact
  end
end
