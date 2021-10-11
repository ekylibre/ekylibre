module Backend
  module PurchaseInvoicesHelper
    def purchase_invoice_badges(purchase_invoice)
      incident = purchase_invoice.reception_items.any?(&:non_compliant) ? :incident : nil

      state_badge_set(incident, states: { incident: :reception_incident }, html: { id: 'incident-badge' })+
        state_badge_set(purchase_invoice.reconciliation_state, states: %i[reconcile to_reconcile accepted], html: { id: 'reconciliation-badges' })
    end
  end
end
