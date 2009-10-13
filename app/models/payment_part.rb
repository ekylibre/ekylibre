# == Schema Information
#
# Table name: payment_parts
#
#  amount       :decimal(16, 2 
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  downpayment  :boolean       not null
#  expense_id   :integer       default(0), not null
#  expense_type :string(255)   default("UnknownModel"), not null
#  id           :integer       not null, primary key
#  invoice_id   :integer       
#  lock_version :integer       default(0), not null
#  payment_id   :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class PaymentPart < ActiveRecord::Base
  belongs_to :company
  belongs_to :payment
  belongs_to :expense, :polymorphic=>true
  belongs_to :invoice # TODEL
  attr_readonly :company_id

  cattr_reader :expense_types
  @@expense_types = [SaleOrder.name, Transfer.name]


  validates_presence_of :expense_id, :expense_type

  def before_validation
    # self.expense_type ||= self.expense.class.name
  end

  def validate
    errors.add(:expense_type, tc(:invalid)) unless @@expense_types.include? self.expense_type
    errors.add_to_base tc(:error_sale_order_already_paid) if self.amount <= 0 and self.downpayment == false
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
 

end
