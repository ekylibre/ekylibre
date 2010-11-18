# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
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
#  amount           :decimal(16, 2)   default(0.0), not null
#  company_id       :integer          not null
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


class OutgoingPaymentUse < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  belongs_to :expense, :class_name=>PurchaseOrder.name
  belongs_to :journal_entry
  belongs_to :payment, :class_name=>OutgoingPayment.name

  autosave :expense, :payment

  validates_numericality_of :amount, :greater_than=>0

  before_validation do
    self.downpayment = false if self.downpayment.nil?
    return true
  end

  validate do
    errors.add_to_base(:nothing_to_pay) if self.amount <= 0 and self.downpayment == false
  end

  bookkeep do |b|
    label = tc(:bookkeep, :resource=>self.class.human_name, :expense_number=>self.expense.number, :payment_number=>self.payment.number, :attorney=>self.payment.payee.full_name, :supplier=>self.expense.supplier.full_name, :mode=>self.payment.mode.name)
    b.journal_entry(self.company.journal(:various), :printed_on=>self.payment.created_on, :unless=>(self.expense.supplier_id == self.payment.payee_id)) do |entry|
      entry.add_debit(label, self.expense.supplier.account(:supplier).id, self.amount)
      entry.add_credit(label, self.payment.payee.account(:attorney).id, self.amount)
    end
    # self.link_in_accountancy
  end

  def payment_way
    self.payment.mode.name if self.payment.mode
  end

  def expenses_and_payments(expenses=[], payments=[], depth=0)
    puts "#{depth.to_s.rjust(4)}: expenses: #{expenses.to_sentence}, payments: #{payments.to_sentence}"
    raise Exception.new "Stop" if depth > 10
    for use in self.expense.payment_uses
      unless payments.include? use.payment_id
        payments << use.payment_id 
        use.expenses_and_payments(expenses, payments, depth+1)
      end
    end
    for use in self.payment.uses
      unless expenses.include? use.expense_id
        expenses << use.expense_id 
        use.expenses_and_payments(expenses, payments, depth+1)
      end
    end
    return expenses, payments
  end

  # Find all the neighbours through the payments and expenses
  def neighbours(uses=[])
    for use in self.expense.payment_uses+self.payment.uses
      unless uses.include? use
        uses << use
        use.neighbours
      end
    end
    return uses
  end

  
  # Lazy marking
  def reconciliate
    expenses, payments, amount = [], [], 0.0
    for use in uses = self.neighbours
      unless expenses.include? use.expense
        expenses << use.expense 
        amount += expense.amount_with_taxes
      end
      unless payments.include? use.payment
        payments << use.payment 
        amount -= payment.amount
      end
    end
    return nil unless amount.zero?
    for use in uses
      if use.expense.supplier_id == use.payment.payee_id
        use.expense.supplier.account(:supplier).mark_entries(use.payment.journal_entry, use.expense.journal_entry)
      else
        use.expense.supplier.account(:supplier).mark_entries(use.journal_entry, use.expense.journal_entry)
        use.payment.payee.account(:attorney).mark_entries(use.journal_entry, use.expense.journal_entry)
      end      
    end
    return true
  end

  def link_in_accountancy
    # raise Exception.new [self.expense.amount_with_taxes, self.payment.amount, self.amount].inspect
    if self.expense.amount_with_taxes == self.payment.amount and self.amount == self.payment.amount
      if self.expense.supplier_id == self.payment.payee_id
        self.expense.supplier.account(:supplier).mark_entries(self.payment.journal_entry, self.expense.journal_entry)
      else
        self.expense.supplier.account(:supplier).mark_entries(self.journal_entry, self.expense.journal_entry)
        self.payment.payee.account(:attorney).mark_entries(self.journal_entry, self.expense.journal_entry)
      end
    end    
  end

end
