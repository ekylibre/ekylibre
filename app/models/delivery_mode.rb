# == Schema Information
#
# Table name: delivery_modes
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  code         :string(3)     not null
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class DeliveryMode < ActiveRecord::Base

  has_many :deliveries, :foreign_key=>:mode_id
  belongs_to :company

  attr_readonly :company_id
  

end
