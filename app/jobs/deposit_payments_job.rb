class DepositPaymentsJob < ActiveJob::Base
  queue_as :default

  def perform(id:, payment_ids:, user_id:)
    @deposit = Deposit.find(id)
    payments = payment_ids.map do |p_id|
      IncomingPayment.find(p_id)
    end
    @deposit.update(payments: payments)
    label = I18n.t('models.deposit.bookkeep', resource: @deposit.class.model_name.human, number: @deposit.number, count: @deposit.payments.count, mode: @deposit.mode.name, responsible: @deposit.responsible.label, description: @deposit.description)
    @deposit.journal_entry.update!(name: label)
    User.find(user_id).notifications.create!(deposit_created_params)
  end

  private

    def deposit_created_params
      {
        message: :deposit_created.tl,
        level: :success,
        interpolations: { id: @deposit.id },
        target_url: "/backend/deposits/#{@deposit.id}"
      }
    end
end
