# == Schema Information
#
# Table name: transfers
#
#  amount       :decimal(16, 2 default(0.0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  locked       :boolean       not null
#  parts_amount :decimal(16, 2 default(0.0), not null
#  started_on   :date          
#  stopped_on   :date          
#  supplier_id  :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Transfer < ActiveRecord::Base
  belongs_to :company
  attr_readonly :company_id
  has_many :payment_parts, :as=>:expense

  def before_validation
    self.parts_amount = self.payment_parts.sum(:amount)||0
  end

  def unpaid_amount(options=nil)
    self.amount - self.parts_amount
  end

end
