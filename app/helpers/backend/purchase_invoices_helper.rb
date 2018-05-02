module Backend
  module PurchaseInvoicesHelper
    def reconciliation_state_title(purchase_invoice)
      is_reconciliate = purchase_invoice
                         .items
                         .select{ |purchase_item| purchase_item.parcels_purchase_invoice_items.any? }
                         .any?

      if purchase_invoice.reconciliation_state.to_sym == :accepted
        html_class = 'accepted-title'
        text = :accepted.tl
      else
        if is_reconciliate
          html_class = 'reconcile-title'
          text = :reconcile.tl
        else
          html_class = 'no-reconciliate-title'
          text = :to_reconciliate.tl
        end
      end

      content_tag(:h2, text, class: "reconciliation-title #{html_class}", data: { no_reconciliate_text: :to_reconciliate.tl, accepted_text: :accepted.tl, reconcile_text: :reconcile.tl, reconcile: is_reconciliate })
    end
  end
end
