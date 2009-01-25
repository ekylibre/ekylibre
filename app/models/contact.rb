# == Schema Information
# Schema version: 20081111111111
#
# Table name: contacts
#
#  id            :integer       not null, primary key
#  entity_id     :integer       not null
#  norm_id       :integer       not null
#  default       :boolean       not null
#  closed_on     :date          
#  line_2        :string(38)    
#  line_3        :string(38)    
#  line_4_number :string(38)    
#  line_4_street :string(38)    
#  line_5        :string(38)    
#  line_6_code   :string(38)    
#  line_6_city   :string(38)    
#  address       :string(280)   
#  phone         :string(32)    
#  fax           :string(32)    
#  mobile        :string(32)    
#  email         :string(255)   
#  website       :string(255)   
#  deleted       :boolean       not null
#  latitude      :float         
#  longitude     :float         
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#

class Contact < ActiveRecord::Base
  # belongs_to :element, :polymorphic=> true

  def before_validation
    if self.default
      contacts = Contact.find(:all,:conditions=>{:entity_id=>self.entity_id, :company_id=>self.company_id})
      for contact in contacts
        if contact.id != self.id
          contact.default = false
          contact.save
        end
      end
      self.default = true
    end


    self.address = ""
    lines = [self.line_2,self.line_3,self.line_4_number,self.line_4_street,self.line_5,self.line_6_code,self.line_6_city]

    for x in (0..6) do
      unless lines[x].to_s.empty?
        self.address += " , "+lines[x]
      end
    end 
    self.address.gsub!(/^ ,/ , " ") if self.address=~/^ ,/

  end
  
end
