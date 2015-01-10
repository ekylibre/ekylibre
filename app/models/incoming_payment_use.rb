# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: incoming_payment_uses
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 2)   
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  downpayment      :boolean          not null
#  expense_id       :integer          default(0), not null
#  expense_type     :string(255)      default("UnknownModel"), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  payment_id       :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class IncomingPaymentUse < CompanyRecord
  acts_as_reconcilable :client, :payer
  attr_readonly :company_id
  belongs_to :company
  belongs_to :expense, :polymorphic=>true
  belongs_to :journal_entry
  belongs_to :payment, :class_name=>"IncomingPayment"

  # autosave :expense, :payment

  cattr_reader :expense_types
  @@expense_types = ["Sale", "Transfer"]

  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :allow_nil => true
  validates_length_of :expense_type, :allow_nil => true, :maximum => 255
  validates_inclusion_of :downpayment, :in => [true, false]
  validates_presence_of :company, :expense, :expense_type, :payment
  #]VALIDATORS]
  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :expense, :payment

  before_validation(:on=>:create) do
    self.company_id = self.payment.company_id if self.payment
  end

  before_validation do
    if self.expense and self.payment and self.amount.to_f.zero?
      self.amount = self.reconcilable_amount
    end
    self.downpayment = false if self.downpayment.nil?
    return true
  end

  validate(:on=>:create) do
    if self.expense and self.payment
      errors.add(:amount, :invalid) unless self.amount <= self.reconcilable_amount
    end
  end

  validate(:on=>:update) do
    old = self.class.find(self.id)
    if self.expense and self.payment
      errors.add(:amount, :invalid) unless self.amount <= self.reconcilable_amount+old.amount
    end
  end

  validate do
    errors.add(:expense_type, :invalid) unless @@expense_types.include? self.expense_type
    if self.expense
      errors.add(:expense_id, :invalid) unless self.expense.company_id = self.company_id
    end
    errors.add_to_base(:nothing_to_pay) if self.amount <= 0 and self.downpayment == false
  end

  bookkeep do |b|
    label = tc(:bookkeep, :resource=>self.class.model_name.human, :expense_number=>self.expense.number, :payment_number=>self.payment.number, :attorney=>self.payment.payer.full_name, :client=>self.expense.client.full_name, :mode=>self.payment.mode.name)
    attorney, client = self.payment.payer.account(:client), self.expense.client.account(:client)
    b.journal_entry(self.company.journal(:various), :printed_on=>self.payment.created_on, :unless=>(attorney.id == client.id)) do |entry|
      entry.add_debit(label, attorney.id, self.amount)
      entry.add_credit(label,  client.id, self.amount)
    end
    # self.reconciliate
  end

  after_save :calculate_reconciliated_amounts
  after_destroy :calculate_reconciliated_amounts

  def calculate_reconciliated_amounts
    self.payment.class.update_all({:used_amount=>self.payment.uses.sum(:amount)}, {:id=>self.payment_id})
    expense = self.expense
    if expense.is_a? Sale
      expense.class.update_all({:paid_amount=>expense.uses.sum(:amount) - (expense.credits.sum(:amount)||0)}, {:id=>self.expense_id})
    else
      expense.class.update_all({:paid_amount=>expense.uses.sum(:amount)}, {:id=>self.expense_id})
    end
  end

  def reconcilable_amount
    return (self.expense.unpaid_amount > self.payment.unused_amount ? self.payment.unused_amount : self.expense.unpaid_amount)
  end

  def payment_way
    self.payment.mode.name if self.payment.mode
  end
  
  def real?
    not self.payment.scheduled or (self.payment.scheduled and self.payment.validated)
  end



end
