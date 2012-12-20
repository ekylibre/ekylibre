# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
#  account_number        :string(255)
#  accounted_at          :datetime
#  amount                :decimal(19, 4)   not null
#  bank                  :string(255)
#  check_number          :string(255)
#  commission_account_id :integer
#  commission_amount     :decimal(19, 4)   default(0.0), not null
#  created_at            :datetime         not null
#  created_on            :date
#  creator_id            :integer
#  deposit_id            :integer
#  id                    :integer          not null, primary key
#  journal_entry_id      :integer
#  lock_version          :integer          default(0), not null
#  mode_id               :integer          not null
#  number                :string(255)
#  paid_on               :date
#  payer_id              :integer
#  receipt               :text
#  received              :boolean          default(TRUE), not null
#  responsible_id        :integer
#  scheduled             :boolean          not null
#  to_bank_on            :date             default(CURRENT_DATE), not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#  used_amount           :decimal(19, 4)   not null
#


class IncomingPayment < CompanyRecord
  acts_as_numbered
  belongs_to :commission_account, :class_name=>"Account"
  belongs_to :responsible, :class_name=>"Entity"
  belongs_to :deposit
  belongs_to :journal_entry
  belongs_to :payer, :class_name=>"Entity"
  belongs_to :mode, :class_name=>"IncomingPaymentMode"
  has_many :uses, :class_name=>"IncomingPaymentUse", :foreign_key=>:payment_id, :dependent=>:destroy
  has_many :sales, :through=>:uses, :source=>:expense, :source_type=>"Sale"
  has_many :transfers, :through=>:uses, :source=>:expense, :source_type=>"Transfer"

  autosave :deposit

  attr_readonly :payer_id
  attr_readonly :amount, :account_number, :bank, :check_number, :mode_id, :if=>Proc.new{self.deposit and self.deposit.locked? }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :commission_amount, :used_amount, :allow_nil => true
  validates_length_of :account_number, :bank, :check_number, :number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :received, :scheduled, :in => [true, false]
  validates_presence_of :amount, :commission_amount, :mode, :to_bank_on, :used_amount
  #]VALIDATORS]
  validates_numericality_of :amount, :greater_than=>0
  validates_numericality_of :used_amount, :commission_amount, :greater_than_or_equal_to=>0
  validates_presence_of :payer, :created_on
  validates_presence_of :commission_account, :if=>Proc.new{|p| p.commission_amount!=0}

  delegate :currency, :to => :mode

  default_scope order("id DESC")
  scope :depositables, lambda {
    where("deposit_id IS NULL AND to_bank_on >= ? AND mode_id IN (SELECT id FROM #{IncomingPaymentMode.table_name} WHERE with_deposit = ?)", true, Date.today)
  }

  before_validation(:on=>:create) do
    self.created_on ||= Date.today
    self.to_bank_on ||= Date.today
    self.scheduled = (self.to_bank_on>Date.today ? true : false) # if self.scheduled.nil?
    self.received = false if self.scheduled
    true
  end

  before_validation do
    if self.mode
      self.commission_account ||= self.mode.commission_account
      self.commission_amount ||= self.mode.commission_amount(self.amount)
    end
    self.used_amount = self.uses.sum(:amount)
  end

  validate do
    errors.add(:amount, :greater_than_or_equal_to, :count=>self.used_amount) if self.amount < self.used_amount
  end

  protect(:on => :update) do
    self.deposit.nil? or not self.deposit.locked
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    mode = self.mode
    label = tc(:bookkeep, :resource=>self.class.model_name.human, :number=>self.number, :payer=>self.payer.full_name, :mode=>mode.name, :expenses=>self.uses.collect{|p| p.expense.number}.to_sentence, :check_number=>self.check_number)
    if mode.with_deposit?
      b.journal_entry(mode.depositables_journal, :printed_on=>self.to_bank_on, :unless=>(!mode or !mode.with_accounting? or !self.received)) do |entry|
        entry.add_debit(label,  mode.depositables_account_id, self.amount-self.commission_amount)
        entry.add_debit(label,  self.commission_account_id, self.commission_amount) if self.commission_amount > 0
        entry.add_credit(label, self.payer.account(:client).id, self.amount) unless self.amount.zero?
      end
    else
      b.journal_entry(mode.cash.journal, :printed_on=>self.to_bank_on, :unless=>(!mode or !mode.with_accounting? or !self.received)) do |entry|
        entry.add_debit(label,  mode.cash.account_id, self.amount-self.commission_amount)
        entry.add_debit(label,  self.commission_account_id, self.commission_amount) if self.commission_amount > 0
        entry.add_credit(label, self.payer.account(:client).id, self.amount) unless self.amount.zero?
      end
    end
  end


  # def currency
  #   self.mode.cash.currency
  # end

  def label
    tc(:label, :amount=>I18n.localize(self.amount, :currency=>self.mode.cash.currency), :date=>I18n.localize(self.to_bank_on), :mode=>self.mode.name, :usable_amount=>I18n.localize(self.unused_amount, :currency=>self.mode.cash.currency), :payer=>self.payer.full_name, :number=>self.number)
  end

  def unused_amount
    self.amount-self.used_amount
  end

#   def attorney_amount
#     total = 0
#     for use in self.uses
#       total += use.amount if use.expense.client_id != use.payment.payer_id
#     end
#     return total
#   end

  # Use the maximum available amount to pay the expense between unpaid and unused amounts
  def pay(expense, options={})
    raise Exception.new("Expense must be "+ IncomingPaymentUse.expense_types.collect{|x| "a "+x}.join(" or ")) unless IncomingPaymentUse.expense_types.include? expense.class.name
    # IncomingPaymentUse.destroy_all(:expense_type=>expense.class.name, :expense_id=>expense.id, :payment_id=>self.id)
    # self.reload
    # use_amount = [expense.unpaid_amount, self.unused_amount].min
    use = self.uses.create(:expense=>expense, :downpayment=>options[:downpayment])
    if use.errors.size > 0
      errors.add_from_record(use)
      return false
    end
    return true
  end


end
