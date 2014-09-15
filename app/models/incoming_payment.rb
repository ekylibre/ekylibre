# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: incoming_payments
#
#  accounted_at          :datetime
#  affair_id             :integer
#  amount                :decimal(19, 4)   not null
#  bank_account_number   :string(255)
#  bank_check_number     :string(255)
#  bank_name             :string(255)
#  commission_account_id :integer
#  commission_amount     :decimal(19, 4)   default(0.0), not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string(3)        not null
#  deposit_id            :integer
#  downpayment           :boolean          default(TRUE), not null
#  id                    :integer          not null, primary key
#  journal_entry_id      :integer
#  lock_version          :integer          default(0), not null
#  mode_id               :integer          not null
#  number                :string(255)
#  paid_at               :datetime
#  payer_id              :integer
#  receipt               :text
#  received              :boolean          default(TRUE), not null
#  responsible_id        :integer
#  scheduled             :boolean          not null
#  to_bank_at            :datetime         not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#


class IncomingPayment < Ekylibre::Record::Base
  attr_readonly :payer_id
  attr_readonly :amount, :account_number, :bank, :bank_check_number, :mode_id, if: Proc.new{ self.deposit and self.deposit.locked? }
  belongs_to :commission_account, class_name: "Account"
  belongs_to :responsible, class_name: "User"
  belongs_to :deposit, inverse_of: :payments
  belongs_to :journal_entry
  belongs_to :payer, class_name: "Entity", inverse_of: :incoming_payments
  belongs_to :mode, class_name: "IncomingPaymentMode", inverse_of: :payments
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :commission_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :bank_account_number, :bank_check_number, :bank_name, :number, allow_nil: true, maximum: 255
  validates_inclusion_of :downpayment, :received, :scheduled, in: [true, false]
  validates_presence_of :amount, :commission_amount, :currency, :mode, :to_bank_at
  #]VALIDATORS]
  validates_numericality_of :amount, greater_than: 0.0
  validates_numericality_of :commission_amount, greater_than_or_equal_to: 0.0
  validates_presence_of :payer
  validates_presence_of :commission_account, if: :with_commission?

  acts_as_numbered
  acts_as_affairable :payer, dealt_at: :to_bank_at, role: "client"

  scope :depositables, -> { where("deposit_id IS NULL AND to_bank_at <= ? AND mode_id IN (SELECT id FROM #{IncomingPaymentMode.table_name} WHERE with_deposit = ?)", Time.now, true) }
  scope :depositables_for, lambda { |deposit, mode = nil|
    deposit = Deposit.find(deposit) unless deposit.is_a?(Deposit)
    where("to_bank_at <= ?", Time.now).where("deposit_id = ? OR (deposit_id IS NULL AND mode_id = ?)", deposit.id, (mode ? mode_id : deposit.mode_id))
  }
  scope :last_updateds, -> { order("updated_at DESC") }

  before_validation(on: :create) do
    self.to_bank_at ||= Time.now
    self.scheduled = (self.to_bank_at > Time.now ? true : false)
    self.received = false if self.scheduled
    true
  end

  before_validation do
    if self.mode
      self.commission_account ||= self.mode.commission_account
      self.commission_amount ||= self.mode.commission_amount(self.amount)
      self.currency = self.mode.currency
    end
    true
  end

  validate do
    if self.mode
      errors.add(:currency, :invalid) if self.currency != self.mode.currency
      if self.deposit
        errors.add(:deposit_id, :invalid) if self.mode_id != self.deposit.mode_id
      end
    end
  end

  protect(on: :update) do
    (self.deposit && self.deposit.protected_on_update?) or (self.journal_entry && self.journal_entry.closed?)
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    mode = self.mode
    label = tc(:bookkeep, :resource => self.class.model_name.human, :number => self.number, :payer => self.payer.full_name, :mode => mode.name, :check_number => self.bank_check_number)
    if mode.with_deposit?
      b.journal_entry(mode.depositables_journal, printed_at: self.to_bank_at, :unless => (!mode or !mode.with_accounting? or !self.received)) do |entry|
        entry.add_debit(label,  mode.depositables_account_id, self.amount-self.commission_amount)
        entry.add_debit(label,  self.commission_account_id, self.commission_amount) if self.commission_amount > 0
        entry.add_credit(label, self.payer.account(:client).id, self.amount) unless self.amount.zero?
      end
    else
      b.journal_entry(mode.cash_journal, printed_at: self.to_bank_at, :unless => (!mode or !mode.with_accounting? or !self.received)) do |entry|
        entry.add_debit(label,  mode.cash.account_id, self.amount-self.commission_amount)
        entry.add_debit(label,  self.commission_account_id, self.commission_amount) if self.commission_amount > 0
        entry.add_credit(label, self.payer.account(:client).id, self.amount) unless self.amount.zero?
      end
    end
  end

  # Returns true if payment is already deposited
  def deposited?
    !!self.deposit
  end
  alias :deposit? :deposited?

  # Returns if a commission is taken
  def with_commission?
    self.mode and self.mode.with_commission?
  end

  # Build and return a label for the payment
  def label
    tc(:label, :amount => I18n.localize(self.amount, currency: self.mode.cash.currency), :date => I18n.localize(self.to_bank_at), :mode => self.mode.name, :payer => self.payer.full_name, :number => self.number) # , :usable_amount => I18n.localize(self.unused_amount, currency: self.mode.cash.currency)
  end

end
