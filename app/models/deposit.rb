# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: deposits
#
#  accounted_at     :datetime
#  amount           :decimal(19, 4)   default(0.0), not null
#  cash_id          :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  description      :text
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  locked           :boolean          not null
#  mode_id          :integer          not null
#  number           :string           not null
#  payments_count   :integer          default(0), not null
#  responsible_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Deposit < Ekylibre::Record::Base
  acts_as_numbered
  belongs_to :cash
  belongs_to :responsible, class_name: "Person"
  belongs_to :journal_entry
  belongs_to :mode, class_name: "IncomingPaymentMode"
  has_many :payments, class_name: "IncomingPayment", dependent: :nullify, counter_cache: true, inverse_of: :deposit
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :accounted_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :amount, allow_nil: true
  validates_inclusion_of :locked, in: [true, false]
  validates_presence_of :amount, :cash, :mode, :number
  #]VALIDATORS]
  validates_presence_of :responsible, :cash

  delegate :currency, to: :cash
  delegate :detail_payments, to: :mode

  scope :unvalidateds, -> { where(locked: false) }

  before_validation do
    self.cash = self.mode.cash if self.mode
  end

  after_save do
    self.update_columns(amount: self.payments.sum(:amount), payments_count: self.payments.count)
  end

  # validate do
  #   if self.cash
  #     error.add(:cash_id, :must_be_a_bank_account) unless self.cash.bank_account?
  #   end
  # end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    payments = self.reload.payments unless b.action == :destroy
    amount = self.payments.sum(:amount)
    b.journal_entry(self.cash.journal, if: !self.mode.depositables_account.nil?) do |entry|

      commissions, commissions_amount = {}, 0
      for payment in payments
        commissions[payment.commission_account_id.to_s] ||= 0
        commissions[payment.commission_account_id.to_s] += payment.commission_amount
        commissions_amount += payment.commission_amount
      end

      label = tc(:bookkeep, resource: self.class.model_name.human, number: self.number, count: self.payments_count, mode: self.mode.name, responsible: self.responsible.label, description: self.description)

      entry.add_debit(label, self.cash.account_id, amount - commissions_amount)
      for commission_account_id, commission_amount in commissions
        entry.add_debit(label, commission_account_id.to_i, commission_amount) if commission_amount > 0
      end

      if self.detail_payments # Preference[:detail_payments_in_deposit_bookkeeping]
        for payment in payments
          label = tc(:bookkeep_with_payment, resource: self.class.model_name.human, number: self.number, mode: self.mode.name, payer: payment.payer.full_name, check_number: payment.bank_check_number, payment: payment.number)
          entry.add_credit(label, self.mode.depositables_account_id, payment.amount)
        end
      else
        entry.add_credit(label, self.mode.depositables_account_id, amount)
      end
      true
    end
  end

  protect do
    self.locked? or (self.journal_entry and self.journal_entry.closed?)
  end

end
