# == Schema Information
# Schema version: 20090311124450
#
# Table name: payments
#
#  id           :integer       not null, primary key
#  paid_on      :date          
#  amount       :decimal(16, 2 
#  mode_id      :integer       not null
#  account_id   :integer       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Payment < ActiveRecord::Base

  def before_destroy
  end

end
