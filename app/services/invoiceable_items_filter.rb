class InvoiceableItemsFilter
    def filter(receptions)
      receptions.flat_map do |reception|
        reception.items.map do |item|
          invoice_item_attributes = {
            variant_id: item.variant_id,
            purchase_id: item.parcel_id,
            currency: item.currency,
            unit_pretax_amount: item.unit_pretax_amount,
            pretax_amount: item.pretax_amount,
            role: item.role,
            quantity: item.quantity,
            tax_id: item.purchase_order_item&.tax_id,
            activity_budget_id: item.activity_budget_id,
            project_budget_id: item.project_budget_id,
            team_id: item.team_id,
            equipment_id: item.equipment_id,
            annotation: item.annotation,
            parcels_purchase_invoice_items: [item]
          }

          PurchaseItem.new(invoice_item_attributes)
        end
      end.compact
    end
  end
  