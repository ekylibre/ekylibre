module Backend
  module PurchaseInvoicesHelper
    def purchase_invoice_incident_badge(purchase_invoice)
      content_tag :h2, :reception_incident.tl, class: ['global-incident-warning reconciliation-title compliance-title', (:hidden unless purchase_invoice.reception_items.any? &:non_compliant)]
    end

    def purchase_reconciliation_state(purchase_invoice, print_both: false)
      elements = ''.html_safe
      if print_both || purchase_invoice.reconciliation_state == 'to_reconcile'
        html_class = 'no-reconciliate-title'
        text = :to_reconciliate.tl
        elements << content_tag(:h2, text, class: ['reconciliation-title', html_class, (:hidden if purchase_invoice.reconciliation_state == 'reconcile')])
      end

      if print_both || purchase_invoice.reconciliation_state == 'reconcile'
        html_class = 'reconcile-title'
        text = :reconcile.tl
        elements << content_tag(:h2, text, class: ['reconciliation-title', html_class, (:hidden if purchase_invoice.reconciliation_state == 'to_reconcile')])
      end

      elements
    end
  end
end
