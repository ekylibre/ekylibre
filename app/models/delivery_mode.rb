# == Schema Information
#
# Table name: delivery_modes
#
#  code         :string(3)     not null
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class DeliveryMode < ActiveRecord::Base

  has_many :deliveries, :foreign_key=>:mode_id
  belongs_to :company

  attr_readonly :company_id
  

end
