# == Schema Information
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
#  entity_id      :integer       
#  to_bank_on     :date          default(Tue, 07 Jul 2009), not null
#  embankment_id  :integer       
#  embanker_id    :integer       
#

class Payment < ActiveRecord::Base
  
  belongs_to :account  
  belongs_to :company
  belongs_to :embanker, :class_name=>User.to_s
  belongs_to :embankment
  belongs_to :entity
  belongs_to :mode, :class_name=>PaymentMode.to_s
  has_many :payment_parts

  validates_presence_of :to_bank_on
  
  def after_update
    if !self.embankment_id.nil?
      self.embankment.refresh
    end
  end
  
  

end
