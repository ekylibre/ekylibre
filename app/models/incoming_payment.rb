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
# == Table: incoming_payments
#
#  accounted_at          :datetime
#  affair_id             :integer
#  amount                :decimal(19, 4)   not null
#  bank_account_number   :string
#  bank_check_number     :string
#  bank_name             :string
#  codes                 :jsonb
#  commission_account_id :integer
#  commission_amount     :decimal(19, 4)   default(0.0), not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string           not null
#  custom_fields         :jsonb
#  deposit_id            :integer
#  downpayment           :boolean          default(TRUE), not null
#  id                    :integer          not null, primary key
#  journal_entry_id      :integer
#  lock_version          :integer          default(0), not null
#  mode_id               :integer          not null
#  number                :string
#  paid_at               :datetime
#  payer_id              :integer
#  provider              :jsonb
#  providers             :jsonb
#  receipt               :text
#  received              :boolean          default(TRUE), not null
#  responsible_id        :integer
#  scheduled             :boolean          default(FALSE), not null
#  to_bank_at            :datetime         not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#

class IncomingPayment < Ekylibre::Record::Base
  include Letterable
  include Attachable
  include PeriodicCalculable
  include Customizable
  include Providable
  attr_readonly :payer_id
  attr_readonly :amount, :account_number, :bank, :bank_check_number, :mode_id, if: proc { deposit && deposit.locked? }
  refers_to :currency
  belongs_to :commission_account, class_name: 'Account'
  belongs_to :responsible, class_name: 'User'
  belongs_to :deposit, inverse_of: :payments
  belongs_to :journal_entry #, dependent: :destroy DO NOT USE HERE because we cancel the bookkeep if needed
  belongs_to :payer, class_name: 'Entity', inverse_of: :incoming_payments
  belongs_to :mode, class_name: 'IncomingPaymentMode', inverse_of: :payments
  has_many :journal_entry_items, through: :journal_entry
  has_one :bank_statement, -> { first }, through: :journal_entry_items
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :paid_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :commission_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :bank_account_number, :bank_check_number, :bank_name, :number, length: { maximum: 500 }, allow_blank: true
  validates :currency, :mode, presence: true
  validates :downpayment, :received, :scheduled, inclusion: { in: [true, false] }
  validates :receipt, length: { maximum: 500_000 }, allow_blank: true
  validates :to_bank_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :amount, numericality: true
  validates :commission_amount, numericality: { greater_than_or_equal_to: 0.0 }
  validates :payer, presence: true
  validates :commission_account, presence: { if: :with_commission? }
  validates :to_bank_at, financial_year_writeable: true

  validates :currency, match: { with: :mode }
  validates :mode, match: { with: :deposit, to_invalidate: :deposit_id }, allow_blank: true

  alias_attribute :third_id, :payer_id

  acts_as_numbered
  acts_as_affairable :payer, dealt_at: :to_bank_at, class_name: 'SaleAffair'

  alias status affair_status

  scope :depositables, -> { where("deposit_id IS NULL AND to_bank_at <= ? AND mode_id IN (SELECT id FROM #{IncomingPaymentMode.table_name} WHERE with_deposit = ?)", Time.zone.now, true) }

  scope :depositables_for, lambda { |deposit, mode = nil|
    deposit = Deposit.find(deposit) unless deposit.is_a?(Deposit)
    where('to_bank_at <= ?', Time.zone.now).where('deposit_id = ? OR (deposit_id IS NULL AND mode_id = ?)', deposit.id, (mode ? mode_id : deposit.mode_id))
  }
  scope :last_updateds, -> { order(updated_at: :desc) }

  scope :between, lambda { |started_at, stopped_at|
    where(paid_at: started_at..stopped_at)
  }
  scope :matching_cash, ->(id) { includes(:mode).where(incoming_payment_modes: { cash_id: id }) }

  calculable period: :month, column: :amount, at: :paid_at, name: :sum

  before_validation(on: :create) do
    self.to_bank_at ||= Time.zone.now
    self.scheduled = (self.to_bank_at > Time.zone.now)
    self.received = false if scheduled
    true
  end

  before_validation do
    if mode
      self.commission_account ||= mode.commission_account
      self.commission_amount ||= mode.commission_amount(amount)
      self.currency = mode.currency
    end
    true
  end

  after_destroy do
    journal_entry.remove if journal_entry.draft?
  end

  protect do
    (deposit && deposit.protected_on_update?) ||
      (journal_entry && journal_entry.closed?) ||
      pointed_by_bank_statement?
  end

  # protect(on: :update) do |p|
  #   p.when :pointed_by_bank_statement
  #   p.when :closed_journal_period, definitive: true
  #   p.when :locked_deposit, definitive: true
  # end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    # mode = mode
    label = tc(:bookkeep, resource: self.class.model_name.human, number: number, payer: payer.full_name, mode: mode.name, check_number: bank_check_number)
    if mode.with_deposit?
      b.journal_entry(mode.depositables_journal, printed_on: self.to_bank_at.to_date, if: (mode && mode.with_accounting? && received), as: :waiting_incoming_payment, column: :journal_entry_id) do |entry|
        entry.add_debit(label,  mode.depositables_account_id, amount - self.commission_amount, as: :deposited)
        entry.add_debit(label,  commission_account_id, self.commission_amount, as: :commission) if self.commission_amount > 0
        entry.add_credit(label, payer.account(:client).id, amount, as: :payer, resource: payer) unless amount.zero?
      end
    else
      b.journal_entry(mode.cash_journal, printed_on: self.to_bank_at.to_date, if: (mode && mode.with_accounting? && received)) do |entry|
        entry.add_debit(label,  mode.cash.account_id, amount - self.commission_amount, as: :bank)
        entry.add_debit(label,  commission_account_id, self.commission_amount, as: :commission) if self.commission_amount > 0
        entry.add_credit(label, payer.account(:client).id, amount, as: :payer, resource: payer) unless amount.zero?
      end
    end
  end

  delegate :third_attribute, to: :class

  def self.third_attribute
    :payer
  end

  def self.sign_of_amount
    1
  end

  def relative_amount
    self.class.sign_of_amount * amount
  end

  def third
    send(third_attribute)
  end

  def pointed_by_bank_statement?
    journal_entry && journal_entry.items.where('LENGTH(TRIM(bank_statement_letter)) > 0').any?
  end

  # Returns true if payment is already deposited
  def deposited?
    !!deposit
  end
  alias deposit? deposited?

  # Returns if a commission is taken
  def with_commission?
    mode && mode.with_commission?
  end

  # Build and return a label for the payment
  def label
    tc(:label, amount: amount.l(currency: mode.cash.currency), date: self.to_bank_at.l, mode: mode.name, payer: payer.full_name, number: number)
  end
end
