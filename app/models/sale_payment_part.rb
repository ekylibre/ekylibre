# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: sale_payment_parts
#
#  accounted_at      :datetime         
#  amount            :decimal(16, 2)   
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  downpayment       :boolean          not null
#  expense_id        :integer          default(0), not null
#  expense_type      :string(255)      default("UnknownModel"), not null
#  id                :integer          not null, primary key
#  journal_record_id :integer          
#  lock_version      :integer          default(0), not null
#  payment_id        :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#

class SalePaymentPart < ActiveRecord::Base
  acts_as_accountable
  attr_readonly :company_id
  belongs_to :company
  belongs_to :expense, :polymorphic=>true
  belongs_to :journal_record
  belongs_to :payment, :class_name=>SalePayment.name

  # belongs_to :invoice # TODEL

  cattr_reader :expense_types
  @@expense_types = [SaleOrder.name, Transfer.name] # PurchaseOrder.name, 

  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :expense_id, :expense_type

  def before_validation
    # self.expense_type ||= self.expense.class.name
    self.downpayment = false if self.downpayment.nil?
    return true
  end

  def validate
    errors.add(:expense_type, :invalid) unless @@expense_types.include? self.expense_type
    errors.add_to_base(:nothing_to_pay) if self.amount <= 0 and self.downpayment == false
  end

  def after_save
    self.payment.save
    self.expense.save 
  end

  def after_destroy
    self.payment.save
    self.expense.save
  end

  def payment_way
    self.payment.mode.name if self.payment.mode
  end
  
  def real?
    not self.payment.scheduled or (self.payment.scheduled and self.payment.validated)
  end
   

  def to_accountancy(action=:create, options={})
    accountize(action, {:journal=>self.payment.mode.cash.journal, :draft_mode=>options[:draft]}, :unless=>(self.journal_record.nil? and self.expense.payer_id == self.payment.client_id)) do |record|
      record.add_debit( tc(:to_accountancy, :resource=>self.class.human_name, :number=>self.number, :detail=>self.payment.payer.full_name), self.payment.payer.account(:attorney).id, self.amount)
      record.add_credit(tc(:to_accountancy, :resource=>self.class.human_name, :number=>self.number, :detail=>self.expense.client.full_name), self.expense.client.account(:client).id, self.amount)
    end
  end

end
