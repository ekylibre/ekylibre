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
#  downpayment    :boolean       not null
#  embanker_id    :integer       
#  embankment_id  :integer       
#  entity_id      :integer       
#  id             :integer       not null, primary key
#  lock_version   :integer       default(0), not null
#  mode_id        :integer       not null
#  paid_on        :date          
#  part_amount    :decimal(16, 2 
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
  has_many :orders, :through=>:parts
  attr_readonly :company_id, :entity_id
  attr_protected :part_amount, :account_id, :account_number

  validates_numericality_of :amount, :greater_than=>0
  validates_presence_of :to_bank_on

  def before_validation_on_create
    self.scheduled = (self.to_bank_on>Date.today ? true : false) if self.scheduled.nil?
    self.received = true unless self.scheduled
  end

  def before_validation
    self.part_amount = self.parts.sum(:amount)
  end
  
  def after_update
    if !self.embankment_id.nil?
      self.embankment.refresh
    end
  end
  
  # Use the minimum amount to pay the order
  # If the payment is a downpayment, we look at the total unpaid amount
  def pay(order)
    PaymentPart.destroy(self.parts.find_all_by_order_id(order.id))
    self.reload
    minimum = [order.unpaid_amount(!self.downpayment), self.amount-self.part_amount].min
    part = self.parts.create(:amount=>minimum, :order_id=>order.id, :company_id=>self.company_id)
    if part.errors.size>0
      part.errors.each_full { |msg| self.errors.add_to_base(msg) }
      return false
    else
      return true
    end
  end

end
