# == Schema Information
# Schema version: 20090407073247
#
# Table name: payments
#
#  id             :integer       not null, primary key
#  paid_on        :date          
#  amount         :decimal(16, 2 not null
#  mode_id        :integer       not null
#  account_id     :integer       
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#  part_amount    :decimal(16, 2 
#  bank           :string(255)   
#  check_number   :string(255)   
#  account_number :string(255)   
#

class Payment < ActiveRecord::Base
  
  belongs_to :account
  belongs_to :company
  belongs_to :payment_mode
  has_many :payment_parts
  
  def before_destroy
  end

 
end
