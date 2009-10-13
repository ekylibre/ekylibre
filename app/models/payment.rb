# == Schema Information
#
# Table name: payments
#
#  account_id     :integer       
#  account_number :string(255)   
#  amount         :decimal(16, 2 not null
#  bank           :string(255)   
#  check_number   :string(255)   
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  creator_id     :integer       
#  embanker_id    :integer       
#  embankment_id  :integer       
#  entity_id      :integer       
#  id             :integer       not null, primary key
#  lock_version   :integer       default(0), not null
#  mode_id        :integer       not null
#  number         :string(255)   
#  paid_on        :date          
#  parts_amount   :decimal(16, 2 
#  received       :boolean       default(TRUE), not null
#  scheduled      :boolean       not null
#  to_bank_on     :date          default(CURRENT_DATE), not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
#

class Payment < ActiveRecord::Base
  belongs_to :account  
  belongs_to :company
  belongs_to :embanker, :class_name=>User.name
  belongs_to :embankment
  belongs_to :entity
  belongs_to :mode, :class_name=>PaymentMode.name
  has_many :parts, :class_name=>PaymentPart.name
  has_many :orders, :through=>:parts, :source=>:expense, :source_type=>'SaleOrder'
  has_many :sale_orders, :through=>:parts, :source=>:expense, :source_type=>'SaleOrder'
  has_many :transfers, :through=>:parts, :source=>:expense, :source_type=>'Transfer'

  attr_readonly :company_id, :entity_id
  attr_protected :parts_amount, :account_id

  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :to_bank_on, :entity_id

  def before_validation_on_create
    specific_numeration = self.company.parameter("management.payments.numeration").value
    if not specific_numeration.nil?
      self.number = specific_numeration.next_value
    else
      last = self.company.payments.find(:first, :conditions=>["company_id=? AND number IS NOT NULL", self.company_id], :order=>"number desc")
      self.number = last ? last.number.succ : '000000'
    end
    self.scheduled = (self.to_bank_on>Date.today ? true : false) #if self.scheduled.nil?
    self.received = false if self.scheduled
    true
  end

  def before_validation
    self.parts_amount = self.parts.sum(:amount)
  end


  def validate
    errors.add(:amount, ::I18n.t('activerecord.errors.messages.greater_than_or_equal_to', :count=>self.parts_amount)) if self.amount < self.parts_amount
  end
  
  def after_update
    if !self.embankment_id.nil?
      self.embankment.refresh
    end
  end  

  
  # Use the minimum amount to pay the expense
  # If the payment is a downpayment, we look at the total unpaid amount
  def pay(expense, options={})
    raise Exception.new("Expense must be "+ PaymentPart.expense_types.collect{|x| "a "+x}.join(" or ")) unless PaymentPart.expense_types.include? expense.class.name
    downpayment = options[:downpayment]
    PaymentPart.destroy_all(:expense_type=>expense.class.name, :expense_id=>expense.id, :payment_id=>self.id)
    self.reload
    part_amount = [expense.unpaid_amount(!downpayment), self.amount-self.parts_amount].min
    part = self.parts.create(:amount=>part_amount, :expense=>expense, :company_id=>self.company_id, :downpayment=>downpayment)
    if part.errors.size > 0
      # part.errors.each_full { |msg| self.errors.add_to_base(msg) }
      self.errors << part.errors.full_messages
      return false
    end
    return true
  end


#   def pay(order, downpayment=false)
#     PaymentPart.destroy(self.parts.find_all_by_order_id(order.id))
#     self.reload
#    # minimum = [order.unpaid_amount(!self.downpayment), self.amount-self.parts_amount].min
#     minimum = [order.unpaid_amount(!downpayment), self.amount-self.parts_amount].min
#     part = self.parts.create(:amount=>minimum, :order_id=>order.id, :company_id=>self.company_id, :downpayment=>downpayment)
#     if part.errors.size>0
#       part.errors.each_full { |msg| self.errors.add_to_base(msg) }
#       return false
#     else
#       return true
#     end
#   end

end
