# == Schema Information
#
# Table name: transports
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#  weight       :decimal(, )   
#

class Transport < ActiveRecord::Base

  belongs_to :company
  belongs_to :transporter, :class_name=>Entity.name
  has_many :deliveries

  attr_readonly :company_id

end
