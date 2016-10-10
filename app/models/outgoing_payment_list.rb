# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: outgoing_payment_lists
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  number     :string
#  updated_at :datetime         not null
#
class OutgoingPaymentList < Ekylibre::Record::Base
  has_many :payments, class_name: 'OutgoingPayment', foreign_key: :list_id, inverse_of: :list, dependent: :destroy

  delegate :name, to: :mode, prefix: true
  delegate :sepa?, to: :mode
  delegate :count, to: :payments, prefix: true

  acts_as_numbered

  protect(on: :destroy) do
    payments
      .includes(journal_entry: :items)
      .map(&:journal_entry)
      .flatten
      .map(&:items)
      .flatten
      .any? { |i| i.bank_statement_letter.present? }
  end

  def mode
    payments.first.mode
  end

  def currency
    mode.cash.currency
  end

  def to_sepa
    sct = SEPA::CreditTransfer.new(
      name: mode.cash.bank_account_holder_name.truncate(70, omission: ''),
      bic: mode.cash.bank_identifier_code || 'NOTPROVIDED',
      iban: mode.cash.iban
    )

    sct.message_identification =
      "EKY-#{self.number}-#{Time.zone.now.strftime('%y%m%d-%H%M')}"

    payments.each do |payment|
      credit_transfer_params = {
        name: payment.payee.bank_account_holder_name.truncate(70, omission: ''),
        iban: payment.payee.iban,
        amount: format('%.2f', payment.amount.round(2)),
        reference: payment.number,
        remittance_information: payment.affair.purchases.first.number,
        requested_date: Time.zone.now.to_date,
        batch_booking: false
      }

      if payment.payee.bank_identifier_code.present?
        credit_transfer_params[:bic] = payment.payee.bank_identifier_code
      else
        credit_transfer_params[:bic] = 'NOTPROVIDED'
      end

      sct.add_transaction(credit_transfer_params)
    end

    sct.to_xml('pain.001.001.03')
  end

  def payments_sum
    payments.sum(:amount)
  end

  def self.build_from_purchases(purchases, mode, responsible)
    outgoing_payments = purchases.map do |purchase|
      OutgoingPayment.new(
        affair: purchase.affair,
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
