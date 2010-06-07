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
#  account_number :string(255)      
#  accounted_at   :datetime         
#  amount         :decimal(16, 2)   not null
#  bank           :string(255)      
#  check_number   :string(255)      
#  company_id     :integer          not null
#  created_at     :datetime         not null
#  created_on     :date             
#  creator_id     :integer          
#  embanker_id    :integer          
#  embankment_id  :integer          
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  mode_id        :integer          not null
#  number         :string(255)      
#  paid_on        :date             
#  parts_amount   :decimal(16, 2)   
#  payer_id       :integer          
#  receipt        :text             
#  received       :boolean          default(TRUE), not null
#  scheduled      :boolean          not null
#  to_bank_on     :date             default(CURRENT_DATE), not null
#  updated_at     :datetime         not null
#  updater_id     :integer          
#

class SalePayment < ActiveRecord::Base
  # belongs_to :account  
  attr_readonly :company_id
  belongs_to :company
  belongs_to :embanker, :class_name=>User.name
  belongs_to :embankment
  # belongs_to :entity
  belongs_to :payer, :class_name=>Entity.name
  belongs_to :mode, :class_name=>SalePaymentMode.name
  has_many :parts, :class_name=>SalePaymentPart.name, :foreign_key=>:payment_id
  # has_many :orders, :through=>:parts, :source=>:expense, :source_type=>SaleOrder.name
  has_many :sale_orders, :through=>:parts, :source=>:expense, :source_type=>SaleOrder.name
  # has_many :purchase_orders, :through=>:parts, :source=>:expense, :source_type=>PurchaseOrder.name
  has_many :transfers, :through=>:parts, :source=>:expense, :source_type=>Transfer.name

  attr_readonly :company_id, :payer_id
  attr_protected :parts_amount, :account_id

  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :to_bank_on, :payer, :created_on
  #validates_presence_of :account_id
  
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

  # Create initial journal record
  def after_create
    #self.to_accountancy if self.company.accountizing?
  end

  # Add journal records in order to correct accountancy
  def before_update
    #self.to_accountancy(:update) if self.company.accountizing?
  end

  def before_destroy
    #self.to_accountancy(:delete) if self.company.accountizing?
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
    (self.amount||0)-(self.parts_amount||0)
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
  # The options :old permits to cancel the old existing record by adding counter-entries
  def to_accountancy2(mode=:create, options={})
    raise Exception.new("Unvalid mode #{mode.inspect}") unless [:create, :update, :delete].include? mode
    journal = self.company.journal(mode == :create ? :bank : :various)
    record = journal.records.create!(:resource=>self, :printed_on=>self.created_on)
    # Add counter-entries
    if mode != :create
      old = self.class.find_by_id(self.id)      
      if old.given?
        record.add_debit( tc(:to_accountancy_cancel, :number=>old.number, :detail=>old.mode.name), old.mode.account.id, old.amount)
        record.add_credit(tc(:to_accountancy_cancel, :number=>old.number, :detail=>old.entity.full_name), old.entity.account(:supplier).id, old.amount)
      else
        record.add_debit( tc(:to_accountancy_cancel, :number=>old.number, :detail=>old.entity.full_name), old.entity.account(:client).id, old.amount)
        record.add_credit(tc(:to_accountancy_cancel, :number=>old.number, :detail=>old.mode.name), old.mode.account_id, old.amount)
      end    
    end
    # Add entries
    if mode != :delete
      if self.given?
        record.add_debit( tc(:to_accountancy, :number=>self.number, :detail=>self.payer.full_name), self.payer.account(:supplier).id, self.amount)
        record.add_credit(tc(:to_accountancy, :number=>self.number, :detail=>self.mode.name), self.mode.account.id, self.amount)
      else
        record.add_debit( tc(:to_accountancy, :number=>self.number, :detail=>self.mode.name), self.mode.account_id, self.amount)
        record.add_credit(tc(:to_accountancy, :number=>self.number, :detail=>self.payer.full_name), self.payer.account(:client).id, self.amount)
      end    
    end

    self.update_attribute(:accounted_at, Time.now)      
  end


 #this method accountizes the payment.
  def to_accountancy
    financialyear = self.company.financialyears.find(:first, :conditions => ["(? BETWEEN started_on and stopped_on) and closed=?", '%'+Date.today.to_s+'%', false])
    
    journal_bank =  self.company.journals.find(:first, :conditions => ['nature = ?', 'bank'])
   
    unless financialyear.nil? or journal_bank.nil?
      record = self.company.journal_records.create!(:resource_id=>self.id, :resource_type=>self.class.name, :created_on=>Date.today, :printed_on => self.created_on, :journal_id=>journal_bank.id, :financialyear_id => financialyear.id)
      
      mode_account_id = self.mode.account_id
      mode_account = self.mode.account.name
      
      account_bank_id = self.company.accounts.find(:first, :conditions=>["number LIKE ?", '512%']).id
      bank_name = (self.mode.cash_id ? (self.mode.cash.bank_name || 'Banque') : 'Banque')

     
      self.parts.each do |part|
            
        if [:SaleOrder].include? part.expense_type.to_sym
          client_id =  self.payer.client_account_id || self.payer.reload.update_attribute(:client_account_id, self.payer.create_update_account(:client).id)
        end
        
        if [:PurchaseOrder].include? part.expense_type.to_sym
          supplier_id =  self.payer.supplier_account_id || self.payer.reload.update_attribute(:supplier_account_id, self.payer.create_update_account(:supplier).id) 
        end
        
        if [:Transfer].include? part.expense_type.to_sym
          transfer_id = part.transfer.supplier.supplier_account_id || self.payer.reload.update_attribute(:supplier_account_id, self.payer.create_update_account(:supplier).id) 
        end
        
        record.add_credit(self.payer.full_name, client_id, part.amount, :draft=>true) if client_id
        record.add_debit(self.payer.full_name, supplier_id, part.amount, :draft=>true) if supplier_id
                
        record.add_debit(bank_name, (self.account_id.nil? ? account_bank_id : self.account_id), part.amount, :draft=>true) if client_id
        record.add_credit(bank_name, (self.account_id.nil? ? account_bank_id : self.account_id), part.amount, :draft=>true) if supplier_id
        
        record.add_debit(mode_account, mode_account_id, part.amount, :draft=>true)
        record.add_credit(mode_account, mode_account_id, part.amount, :draft=>true)
      end
   
      self.update_attribute(:accounted_at, Time.now)
    end
  end
  
end
