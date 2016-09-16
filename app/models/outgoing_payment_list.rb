class OutgoingPaymentList < Ekylibre::Record::Base
  has_many :payments, class_name: 'OutgoingPayment', foreign_key: :list_id, inverse_of: :list, dependent: :restrict_with_error

  delegate :name, to: :mode, prefix: true
  delegate :count, to: :payments, prefix: true

  acts_as_numbered

  def mode
    payments.first.mode
  end

  def self.build_from_purchases(purchases, mode, responsible)
    outgoing_payments = purchases.map do |purchase|
      OutgoingPayment.new(
        # affair: purchase.affair,
        amount: purchase.amount,
        cash: mode.cash,
        currency: purchase.currency,
        delivered: true,
        mode: mode,
        paid_at: Time.zone.today,
        payee: purchase.payee,
        responsible: responsible,
        to_bank_at: Time.zone.today
      )
    end

    new(payments: outgoing_payments)
  end
end
