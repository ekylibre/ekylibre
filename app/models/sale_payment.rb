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
# == Table: sale_payments
#
#  account_number    :string(255)      
#  accounted_at      :datetime         
#  amount            :decimal(16, 2)   not null
#  bank              :string(255)      
#  check_number      :string(255)      
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  created_on        :date             
#  creator_id        :integer          
#  embanker_id       :integer          
#  embankment_id     :integer          
#  id                :integer          not null, primary key
#  journal_record_id :integer          
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          not null
#  number            :string(255)      
#  paid_on           :date             
#  parts_amount      :decimal(16, 2)   not null
#  payer_id          :integer          
#  receipt           :text             
#  received          :boolean          default(TRUE), not null
#  scheduled         :boolean          not null
#  to_bank_on        :date             default(CURRENT_DATE), not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#

class SalePayment < ActiveRecord::Base
  acts_as_accountable
  attr_readonly :company_id
  belongs_to :company
  belongs_to :embanker, :class_name=>User.name
  belongs_to :embankment
  belongs_to :journal_record
  belongs_to :payer, :class_name=>Entity.name
  belongs_to :mode, :class_name=>SalePaymentMode.name
  has_many :parts, :class_name=>SalePaymentPart.name, :foreign_key=>:payment_id
  # has_many :orders, :through=>:parts, :source=>:expense, :source_type=>SaleOrder.name
  has_many :sale_orders, :through=>:parts, :source=>:expense, :source_type=>SaleOrder.name
  # has_many :purchase_orders, :through=>:parts, :source=>:expense, :source_type=>PurchaseOrder.name
  has_many :transfers, :through=>:parts, :source=>:expense, :source_type=>Transfer.name

  attr_readonly :company_id, :payer_id
  attr_protected :parts_amount

  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :to_bank_on, :payer, :created_on
  
  def before_validation_on_create
    self.created_on ||= Date.today
    specific_numeration = self.company.parameter("management.payments.numeration")
    if specific_numeration and specific_numeration.value
      self.number = specific_numeration.value.next_value
    else
      last = self.company.payments.find(:first, :conditions=>["company_id=? AND number IS NOT NULL", self.company_id], :order=>"number desc")
      self.number = last ? last.number.succ : '000000'
    end
    self.scheduled = (self.to_bank_on>Date.today ? true : false) # if self.scheduled.nil?
    self.received = false if self.scheduled
    true
  end

  def before_validation
    self.parts_amount = self.parts.sum(:amount)
  end

  def validate
    errors.add(:amount, :greater_than_or_equal_to, :count=>self.parts_amount) if self.amount < self.parts_amount
  end
  
  def after_update
    if !self.embankment_id.nil?
      self.embankment.refresh
    end
  end

  def label
    tc(:label, :amount=>self.amount.to_s, :date=>self.created_at.to_date, :mode=>self.mode.name, :usable_amount=>self.unused_amount.to_s, :payer=>self.payer.full_name, :number=>self.number)
  end

  def unused_amount
    self.amount-self.parts_amount
  end

  def attorney_amount
    total = 0
    for part in self.parts
      total += part.amount if part.expense.client_id != part.payment.payer_id
    end    
    return total
  end

  # Use the minimum amount to pay the expense
  # If the payment is a downpayment, we look at the total unpaid amount
  def pay(expense, options={})
    raise Exception.new("Expense must be "+ SalePaymentPart.expense_types.collect{|x| "a "+x}.join(" or ")) unless SalePaymentPart.expense_types.include? expense.class.name
    downpayment = options[:downpayment]
    SalePaymentPart.destroy_all(:expense_type=>expense.class.name, :expense_id=>expense.id, :payment_id=>self.id)
    self.reload
    part_amount = [expense.unpaid_amount(!downpayment), self.unused_amount].min
    part = self.parts.create(:amount=>part_amount, :expense=>expense, :company_id=>self.company_id, :downpayment=>downpayment)
    if part.errors.size > 0
      errors.add_from_record(part)
      return false
    end
    return true
  end
  
  # This method permits to add journal entries corresponding to the payment
  # It depends on the parameter which permit to activate the "automatic accountizing"
  def to_accountancy(action=:create, options={})
    attorney_amount = self.attorney_amount
    client_amount   = self.amount - attorney_amount
    label = tc(:to_accountancy, :resource=>self.class.human_name, :number=>self.number, :payer=>self.payer.full_name, :mode=>self.mode.name, :expenses=>self.parts.collect{|p| p.expense.number}.to_sentence, :check_number=>self.check_number)
    accountize(action, {:journal=>self.mode.cash.journal, :draft_mode=>options[:draft]}, :unless=>(!self.mode.with_accounting? or !self.received)) do |record|
      record.add_debit(label, (self.mode.with_embankment? ? self.mode.embankables_account_id : self.mode.cash.account_id), self.amount)
      record.add_credit(label, self.payer.account(:client).id,   client_amount)   unless client_amount.zero?
      record.add_credit(label, self.payer.account(:attorney).id, attorney_amount) unless attorney_amount.zero?
    end
  end
  
end
