module Backend
  module ReceptionsHelper
    def reception_badges(reception)
      incident = reception.late_delivery || reception.items.any?(&:non_compliant) ? :incident : nil

      state_badge_set(incident, states: { incident: :reception_incident }, html: { id: 'incident-badge' }) +
        state_badge_set(reception.reconciliation_state, states: %i[reconcile to_reconcile accepted], html: { id: 'reconciliation-badges' })
    end
  end
end
