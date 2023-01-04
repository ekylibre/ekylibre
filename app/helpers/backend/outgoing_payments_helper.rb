module Backend
  module OutgoingPaymentsHelper
    def outgoing_payment_badges(payment)
      state_badge_set(payment.journal_entry&.state, states: %i[draft confirmed closed], html: { id: 'reconciliation-badges' })
    end
  end
end
