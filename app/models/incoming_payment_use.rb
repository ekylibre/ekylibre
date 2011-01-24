# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2011 Brice Texier, Thibaud Merigon
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
  belongs_to :payment, :class_name=>IncomingPayment.name

  autosave :expense, :payment

  cattr_reader :expense_types
  @@expense_types = [Sale.name, Transfer.name]

  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :expense_id, :expense_type

  before_validation do
    # self.expense_type ||= self.expense.class.name
    self.downpayment = false if self.downpayment.nil?
    return true
  end

  validate do
    errors.add(:expense_type, :invalid) unless @@expense_types.include? self.expense_type
    errors.add_to_base(:nothing_to_pay) if self.amount <= 0 and self.downpayment == false
  end

  bookkeep do |b|
    label = tc(:bookkeep, :resource=>self.class.human_name, :expense_number=>self.expense.number, :payment_number=>self.payment.number, :attorney=>self.payment.payer.full_name, :client=>self.expense.client.full_name, :mode=>self.payment.mode.name)
    b.journal_entry(self.company.journal(:various), :printed_on=>self.payment.created_on, :unless=>(self.expense.client_id == self.payment.payer_id)) do |entry|
      entry.add_debit(label, self.payment.payer.account(:attorney).id, self.amount)
      entry.add_credit(label, self.expense.client.account(:client).id, self.amount)
    end
    self.reconciliate
  end

  def payment_way
    self.payment.mode.name if self.payment.mode
  end
  
  def real?
    not self.payment.scheduled or (self.payment.scheduled and self.payment.validated)
  end



end
