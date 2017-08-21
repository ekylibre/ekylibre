module Backend
  # Abstract controller to manage all outgoing payments.
  # CAUTION: No routes must use this controller.
  class OutgoingPaymentsController < Backend::BaseController
    manage_restfully(
      to_bank_at: 'Time.zone.today'.c,
      paid_at: 'Time.zone.today'.c,
      responsible_id: 'current_user.id'.c,
      amount: 'params[:amount].to_f'.c,
      delivered: true,
      subclass_inheritance: true,
      t3e: {
        payee: :payee_full_name
      }
    )

    unroll :amount, :bank_check_number, :number, :currency, mode: :name, payee: :full_name
  end
end
