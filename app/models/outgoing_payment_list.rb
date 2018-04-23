# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  cached_payment_count :integer
#  cached_total_sum     :decimal(, )
#  created_at           :datetime
#  creator_id           :integer
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  mode_id              :integer          not null
#  number               :string
#  updated_at           :datetime
#  updater_id           :integer
#
class OutgoingPaymentList < Ekylibre::Record::Base
  belongs_to :mode, class_name: 'OutgoingPaymentMode'
  has_many :payments, class_name: 'PurchasePayment', foreign_key: :list_id, inverse_of: :list, dependent: :destroy
  has_one :cash, through: :mode

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :cached_total_sum, numericality: true, allow_blank: true
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :mode, presence: true
  # ]VALIDATORS]

  delegate :name, to: :mode, prefix: true
  delegate :sepa?, to: :mode
  delegate :currency, to: :cash

  acts_as_numbered

  protect(on: :destroy) do
    payments.joins(journal_entry: :items).where('LENGTH(TRIM(journal_entry_items.bank_statement_letter)) > 0 OR journal_entry_items.state = ?', :closed).exists?
  end

  def to_sepa
    sct = SEPA::CreditTransfer.new(
      name: mode.cash.bank_account_holder_name.truncate(70, omission: ''),
      bic: mode.cash.bank_identifier_code || 'NOTPROVIDED',
      iban: mode.cash.iban
    )

    sct.message_identification =
      "EKY-#{number}-#{Time.zone.now.strftime('%y%m%d-%H%M')}"

    payments.each do |payment|
      credit_transfer_params = {
        name: payment.payee.bank_account_holder_name.truncate(70, omission: ''),
        iban: payment.payee.iban,
        amount: format('%.2f', payment.amount.round(2)),
        reference: payment.number,
        remittance_information: payment.affair.purchase_invoices.first.number,
        requested_date: Time.zone.now.to_date,
        batch_booking: false,
        bic: 'NOTPROVIDED'
      }

      if payment.payee.bank_identifier_code.present?
        credit_transfer_params[:bic] = payment.payee.bank_identifier_code
      end

      sct.add_transaction(credit_transfer_params)
    end

    sct.to_xml('pain.001.001.03')
  end

  def remove
    self.class.transaction do
      payment_ids = payments.pluck(:id)
      OutgoingPayment.where(id: payment_ids).update_all(list_id: nil)
      OutgoingPayment.where(id: payment_ids).find_each(&:destroy!)
      destroy!
    end
  end

  def payments_sum
    cached_total_sum
  end

  def payments_count
    cached_payment_count
  end

  def payer
    Entity.of_company
  end

  def self.build_from_purchases(purchases, mode, responsible, initial_check_number = nil)
    build_from_purchase_affairs(purchases.map(&:affair).uniq, mode, responsible, initial_check_number)
  end

  def self.build_from_purchase_affairs(affairs, mode, responsible, initial_check_number = nil)
    purchase_payments = affairs.collect.with_index do |affair, index|
      next if affair.third_credit_balance <= 0
      PurchasePayment.new(
        affair: affair,
        amount: affair.third_credit_balance,
        cash: mode.cash,
        currency: affair.currency,
        delivered: true,
        mode: mode,
        paid_at: Time.zone.today,
        payee: affair.third,
        responsible: responsible,
        to_bank_at: Time.zone.today,
        bank_check_number: initial_check_number.blank? ? nil : initial_check_number.to_i + index,
        position: index
      )
    end.compact
    new(payments: purchase_payments, mode: mode)
  end

  def self.build_from_affairs(affairs, mode, responsible, initial_check_number = nil, ignore_empty_affair = false)
    thirds = affairs.map(&:third).uniq
    position = 0

    purchase_payments = thirds.map do |third|
      third_affairs = affairs.select { |a| a.third == third }.sort_by(&:created_at)
      first_affair = third_affairs.shift
      third_affairs.map { |affair| first_affair.absorb!(affair) }

      next if first_affair.balanced?
      next if ignore_empty_affair && first_affair.third_credit_balance <= 0

      op = PurchasePayment.new(
        affair: first_affair,
        amount: first_affair.third_credit_balance,
        cash: mode.cash,
        currency: first_affair.currency,
        delivered: true,
        mode: mode,
        paid_at: Time.zone.today,
        payee: first_affair.third,
        responsible: responsible,
        to_bank_at: Time.zone.today,
        bank_check_number: initial_check_number.blank? ? nil : initial_check_number.to_i,
        position: position
      )
      initial_check_number = initial_check_number.to_i + 1 if initial_check_number.present?
      position += 1
      op
    end.compact
    new(payments: purchase_payments, mode: mode) unless purchase_payments.empty?
  end
end
