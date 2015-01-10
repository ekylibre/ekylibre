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
# == Table: outgoing_payments
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 2)   default(0.0), not null
#  check_number     :string(255)      
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  created_on       :date             
#  creator_id       :integer          
#  delivered        :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  mode_id          :integer          not null
#  number           :string(255)      
#  paid_on          :date             
#  payee_id         :integer          not null
#  responsible_id   :integer          not null
#  to_bank_on       :date             not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  used_amount      :decimal(16, 2)   default(0.0), not null
#


class OutgoingPayment < CompanyRecord
  acts_as_numbered
  attr_readonly :company_id
  belongs_to :company
  belongs_to :journal_entry
  belongs_to :mode, :class_name=>"OutgoingPaymentMode"
  belongs_to :payee, :class_name=>"Entity"
  belongs_to :responsible, :class_name=>"User"
  has_many :uses, :class_name=>"OutgoingPaymentUse", :foreign_key=>:payment_id, :dependent=>:destroy
  has_many :purchases, :through=>:uses
  has_many :expenses, :through=>:uses
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :used_amount, :allow_nil => true
  validates_length_of :check_number, :number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :delivered, :in => [true, false]
  validates_presence_of :amount, :company, :mode, :payee, :responsible, :to_bank_on, :used_amount
  #]VALIDATORS]
  validates_numericality_of :amount, :greater_than=>0
  validates_numericality_of :used_amount, :greater_than_or_equal_to=>0
  validates_presence_of :to_bank_on, :created_on

  before_validation(:on=>:create) do
    self.created_on ||= Date.today
    true
  end

  before_validation do
    self.used_amount = self.uses.sum(:amount)
  end

  validate do
    errors.add(:amount, :greater_than_or_equal_to, :count=>self.used_amount) if self.amount < self.used_amount
  end

  protect_on_update do
    return (self.journal_entry ? !self.journal_entry.closed? : true)
  end

  protect_on_destroy do
    updateable? and self.used_amount.zero?
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    # attorney_amount = self.attorney_amount
    supplier_amount = self.amount #  - attorney_amount
    label = tc(:bookkeep, :resource=>self.class.model_name.human, :number=>self.number, :payee=>self.payee.full_name, :mode=>self.mode.name, :expenses=>self.uses.collect{|p| p.expense.number}.to_sentence, :check_number=>self.check_number)
    b.journal_entry(self.mode.cash.journal, :printed_on=>self.to_bank_on, :unless=>(!self.mode.with_accounting? or !self.delivered)) do |entry|
      entry.add_debit(label, self.payee.account(:supplier).id, supplier_amount) unless supplier_amount.zero?
      # entry.add_debit(label, self.payee.account(:attorney).id, attorney_amount) unless attorney_amount.zero?
      entry.add_credit(label, self.mode.cash.account_id, self.amount)
    end
    # self.uses.first.reconciliate if self.uses.first
  end


  def label
    tc(:label, :amount=>self.amount.to_s, :date=>self.created_at.to_date, :mode=>self.mode.name, :usable_amount=>self.unused_amount.to_s, :payee=>self.payee.full_name, :number=>self.number, :currency=>self.company.default_currency.symbol)
  end

  def unused_amount
    self.amount-self.used_amount
  end

#   def attorney_amount
#     total = 0
#     for use in self.uses
#       total += use.amount if use.expense.supplier_id != use.payment.payee_id
#     end    
#     return total
#   end

  # Use the maximum available amount to pay the expense
  def pay(expense, options={})
    raise Exception.new("Expense must be Purchase (not #{expense.class.name})") unless expense.class.name == Purchase.name
    # OutgoingPaymentUse.destroy_all(:expense_id=>expense.id, :payment_id=>self.id)
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
