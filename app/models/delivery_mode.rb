class DeliveryMode < ActiveRecord::Base

  has_many :deliveries, :foreign_key=>:mode_id
  belongs_to :company

  attr_readonly :company_id
  

end
