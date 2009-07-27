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
#  paid_on        :date          
#  part_amount    :decimal(16, 2 
#  to_bank_on     :date          default(Wed, 08 Jul 2009), not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
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
