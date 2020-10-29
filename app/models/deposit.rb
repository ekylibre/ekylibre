# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  custom_fields    :jsonb
#  description      :text
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  locked           :boolean          default(FALSE), not null
#  mode_id          :integer          not null
#  number           :string           not null
#  payments_count   :integer          default(0), not null
#  responsible_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Deposit < Ekylibre::Record::Base
  include Customizable
  acts_as_numbered
  belongs_to :cash
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  belongs_to :journal_entry
  belongs_to :mode, class_name: 'IncomingPaymentMode'
  has_many :payments, class_name: 'IncomingPayment', dependent: :nullify, counter_cache: true, inverse_of: :deposit
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :locked, inclusion: { in: [true, false] }
  validates :number, presence: true, length: { maximum: 500 }
  validates :cash, :mode, presence: true
  # ]VALIDATORS]
  validates :responsible, :cash, presence: true

  delegate :currency, to: :cash
  delegate :detail_payments, to: :mode

  scope :unvalidateds, -> { where(locked: false) }

  before_validation do
    self.cash ||= mode.cash if mode
  end

  after_save do
    update_columns(amount: payments.sum(:amount), payments_count: payments.count)
  end

  validate do
    if self.cash
      errors.add(:cash_id, :must_be_a_bank_account) unless self.cash.bank_account?
    end
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    reload unless b.action == :destroy
    amount = payments.sum(:amount)
    b.journal_entry(cash.journal, if: !mode.depositables_account.nil?) do |entry|
      commissions = {}
      commissions_amount = 0
      payments.each do |payment|
        commissions[payment.commission_account_id.to_s] ||= 0
        commissions[payment.commission_account_id.to_s] += payment.commission_amount
        commissions_amount += payment.commission_amount
      end

      label = tc(:bookkeep, resource: self.class.model_name.human, number: number, count: payments_count, mode: mode.name, responsible: responsible.label, description: description)

      entry.add_debit(label, cash.account_id, amount - commissions_amount, as: :bank)
      commissions.each do |commission_account_id, commission_amount|
        entry.add_debit(label, commission_account_id.to_i, commission_amount, as: :commission) if commission_amount > 0
      end

      if detail_payments # Preference[:detail_payments_in_deposit_bookkeeping]
        payments.each do |payment|
          label = tc(:bookkeep_with_payment, resource: self.class.model_name.human, number: number, mode: mode.name, payer: payment.payer.full_name, check_number: payment.bank_check_number, payment: payment.number)
          entry.add_credit(label, mode.depositables_account_id, payment.amount, as: :deposited, resource: payment)
        end
      else
        entry.add_credit(label, mode.depositables_account_id, amount, as: :deposited)
      end
      true
    end
  end

  protect do
    locked? || (journal_entry && journal_entry.closed?)
  end
end
