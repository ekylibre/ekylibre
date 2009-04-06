# == Schema Information
# Schema version: 20090406132452
#
# Table name: payment_modes
#
#  id           :integer       not null, primary key
#  name         :string(50)    not null
#  nature       :string(1)     default("U"), not null
#  account_id   :integer       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#  mode         :string(5)     
#

class PaymentMode < ActiveRecord::Base

  def self.modes
    [:check, :other].collect{|x| [tc('modes.'+x.to_s), x]}
  end


end
