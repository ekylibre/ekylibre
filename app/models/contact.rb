# == Schema Information
# Schema version: 20080819191919
#
# Table name: contacts
#
#  id            :integer       not null, primary key
#  element_id    :integer       not null
#  element_type  :string(255)   
#  norm_id       :integer       not null
#  active        :boolean       default(TRUE), not null
#  default       :boolean       default(TRUE), not null
#  closed_on     :date          
#  line_2        :string(38)    
#  line_3        :string(38)    
#  line_4_number :string(38)    
#  line_4_street :string(38)    
#  line_5        :string(38)    
#  line_6_code   :string(38)    
#  line_6_city   :string(38)    
#  phone         :string(32)    
#  fax           :string(32)    
#  mobile        :string(32)    
#  email         :string(255)   
#  website       :string(255)   
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#

class Contact < ActiveRecord::Base
end
