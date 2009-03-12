# == Schema Information
# Schema version: 20090311124450
#
# Table name: contacts
#
#  id            :integer       not null, primary key
#  name          :string(255)   
#  entity_id     :integer       not null
#  norm_id       :integer       not null
#  code          :string(4)     not null
#  active        :boolean       not null
#  started_at    :datetime
#  stopped_at    :datetime
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
#  country       :string(2)     
#

class Contact < ActiveRecord::Base
  # belongs_to :element, :polymorphic=> true
  attr_protected :name, :entity_id, :company_id, :norm_id, :code, :line_2, :line_3, :line_4_number, :line_4_street,
                  :line_5, :line_6_code, :line_6_city, :adress, :phone, :fax, :mobile, :email, :website, :latitude, :longitude


  def before_validation
    self.default = true if self.entity.contacts.size <= 0
    
    if self.default
      Contact.update_all('"default"=false', ["entity_id=? AND company_id=? AND id!=?", self.entity_id,self.company_id, self.id||0])
    end
    
    lines = [self.line_2, self.line_3, (self.line_4_number+' '+self.line_4_street).strip, self.line_5, (self.line_6_code+" "+self.line_6_city).strip, (self.country.blank? ? '' : I18n.t("countries.#{self.country}"))].compact
    lines.delete ""
    self.address = lines.join(", ")

    self.website = "http://"+self.website unless self.website.blank? or self.website.match /^.+p.*\/\//
  end

  # Each contact have a distinct code for a precise company.  
  def validate_on_create
    raise Exception.new('salut1: '+self.inspect)
    
    unless self.code
      #raise Exception.new('salut1: '+self.inspect)
      self.code = 'AAAA'
      
      while Contact.count(:conditions=>["entity_id=? AND company_id=? AND code=?", self.entity_id, self.company_id, self.code])>0 do
        self.code.succ!
      end
      self.update_attributes!({:active=>true, :started_at=>Time.now})
    end
  
  end


  # A contact can not be modified.
  def validate_on_update
    #contact=Contact.find(self.id)
    #self.attributes=contact.attributes
    errors.add_to_base tc(:error_modify_contact) if self.active
  end

 # This method 
 def upgrade(values)
   now = Time.now
   self.update_attributes({:active=>false, :stopped_at=>now})
   #return self
   #raise Exception.new('ex: '+self.inspect)
   contact = Contact.create(values.merge({:code=>self.code, :active=>true, :started_at=>now, :company_id=>self.company_id, :entity_id=>self.entity_id, :norm_id=>self.norm_id}))
   
   #raise Exception.new('ex: '+contact.to_s)
   #contact
 end

  
end
