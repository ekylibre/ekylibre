# == Schema Information
#
# Table name: transfers
#
#  amount       :decimal(16, 2 default(0.0), not null
#  comment      :string(255)   
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  created_on   :date          
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  label        :string(255)   
#  lock_version :integer       default(0), not null
#  parts_amount :decimal(16, 2 default(0.0), not null
#  started_on   :date          
#  stopped_on   :date          
#  supplier_id  :integer       
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Transfer < ActiveRecord::Base
  belongs_to :company
  attr_readonly :company_id, :comment
  has_many :payment_parts, :as=>:expense

  validates_presence_of :created_on

  def before_validation
    self.created_on ||= Date.today
    self.parts_amount = self.payment_parts.sum(:amount)||0
  end

  def unpaid_amount(options=nil)
    self.amount - self.parts_amount
  end

end
