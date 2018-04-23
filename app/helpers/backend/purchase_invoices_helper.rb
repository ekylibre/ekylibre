module Backend
  module PurchaseInvoicesHelper
    def reconciliation_state_title(purchase_invoice)
      case purchase_invoice.reconciliation_state
      when 'to_reconcile'
        html_class = 'no-reconciliate-title'
        text = :to_reconciliate.tl
      when 'reconcile'
        html_class = 'reconcile-title'
        text = :reconcile.tl
      when 'accepted'
        html_class = 'accepted-title'
        text = :accepted.tl
      end
      content_tag(:h2, text, class: "reconciliation-title #{html_class}", data: { no_reconciliate_text: :to_reconciliate.tl, accepted_text: :accepted.tl })
    end
  end
end
