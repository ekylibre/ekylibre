# frozen_string_literal: true

class ReceivableItemsFilter
  def filter(purchase_orders)
    purchase_orders.flat_map do |purchase_order|
      purchase_order.items.map do |item|
        next if item.quantity_to_receive == 0

        reception_item_attributes = {
          variant_id: item.variant_id,
          purchase_order_item_id: item.id,
          currency: item.currency,
          role: item.role,
          conditioning_quantity: item.quantity_to_receive,
          conditioning_unit_id: item.conditioning_unit_id,
          activity_budget_id: item.activity_budget_id,
          project_budget_id: item.project_budget_id,
          team_id: item.team_id,
          equipment_id: item.equipment_id,
          annotation: item.annotation
        }
        reception_item_storage_attributes = { conditioning_quantity: item.quantity_to_receive, conditioning_unit_id: item.conditioning_unit_id }
        reception_item = ReceptionItem.new(reception_item_attributes)
        reception_item.storings << ParcelItemStoring.new(reception_item_storage_attributes)
        reception_item
      end
    end.compact
  end
end
