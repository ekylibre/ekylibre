class District < ActiveRecord::Base
  belongs_to :company
  has_many :cities
  
  attr_readonly :company_id
end
