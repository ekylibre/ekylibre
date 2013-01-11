# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: outgoing_payment_uses
#
#  accounted_at     :datetime         
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  downpayment      :boolean          not null
#  expense_id       :integer          not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  payment_id       :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class OutgoingPaymentUse < CompanyRecord
  attr_accessible :expense_id, :payment_id
  belongs_to :expense, :class_name => "Purchase"
  belongs_to :purchase, :foreign_key => :expense_id
  belongs_to :journal_entry
  belongs_to :payment, :class_name => "OutgoingPayment"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :allow_nil => true
  validates_inclusion_of :downpayment, :in => [true, false]
  validates_presence_of :amount, :expense, :payment, :purchase
  #]VALIDATORS]
  validates_numericality_of :amount, :greater_than => 0
  validates_presence_of :expense, :payment

  acts_as_reconcilable :supplier, :payee
  # autosave :expense, :payment


  before_validation do
    if self.expense and self.payment and self.amount.to_f.zero?
      self.amount = self.reconcilable_amount
    end
    self.downpayment = false if self.downpayment.nil?
    return true
  end

  validate(:on => :create) do
    if self.expense and self.payment
      errors.add(:payment_id, :currency_does_not_match, :currency => self.expense.currency) unless self.expense.currency == self.payment.currency
      errors.add(:amount, :invalid) unless self.amount <= self.reconcilable_amount
    end
  end

  validate(:on => :update) do
    old = self.class.find(self.id)
    if self.expense and self.payment
      errors.add(:amount, :invalid) unless self.amount <= self.reconcilable_amount+old.amount
    end
  end

  validate do
    errors.add_to_base(:nothing_to_pay) if self.amount <= 0 and self.downpayment == false
  end

  bookkeep do |b|
    label = tc(:bookkeep, :resource => self.class.model_name.human, :expense_number => self.expense.number, :payment_number => self.payment.number, :attorney => self.payment.payee.full_name, :supplier => self.expense.supplier.full_name, :mode => self.payment.mode.name)
    supplier, attorney = self.expense.supplier.account(:supplier), self.payment.payee.account(:supplier)
    b.journal_entry(self.payment.mode.attorney_journal, :printed_on => self.payment.created_on, :unless => (supplier.id == attorney.id)) do |entry|
      entry.add_debit(label,  supplier.id, self.amount)
      entry.add_credit(label, attorney.id, self.amount)
    end
    # self.reconciliate
  end

  after_save :calculate_reconciliated_amounts
  after_destroy :calculate_reconciliated_amounts

  def calculate_reconciliated_amounts
    self.payment.class.update_all({:used_amount => self.payment.uses.sum(:amount)}, {:id => self.payment_id})
    self.expense.class.update_all({:paid_amount => self.expense.uses.sum(:amount)}, {:id => self.expense_id})
  end

  def reconcilable_amount
    return (self.expense.unpaid_amount > self.payment.unused_amount ? self.payment.unused_amount : self.expense.unpaid_amount)
  end

  def payment_way
    self.payment.mode.name if self.payment.mode
  end

end
