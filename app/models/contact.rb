# == Schema Information
# Schema version: 20090410102120
#
# Table name: contacts
#
#  id            :integer       not null, primary key
#  name          :string(255)   
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
#  country       :string(2)     
#  code          :string(4)     
#  active        :boolean       not null
#  started_at    :datetime      
#  stopped_at    :datetime      
#

class Contact < ActiveRecord::Base
  belongs_to :company
  belongs_to :entity
  belongs_to :norm, :class_name=>AddressNorm.to_s
  has_many :deliveries
  has_many :invoices
  has_many :purchase_orders
  has_many :stock_locations

  # belongs_to :element, :polymorphic=> true
  attr_readonly :name, :entity_id, :company_id, :norm_id, :code, :line_2, :line_3, :line_4_number, :line_4_street,
  :line_5, :line_6_code, :line_6_city, :address, :phone, :fax, :mobile, :email, :website
  

  def before_validation
    self.default = true if self.entity.contacts.size <= 0
    
    Contact.update_all({:default=>false}, ["entity_id=? AND company_id=? AND id!=?", self.entity_id,self.company_id, self.id||0]) if self.default
    
    lines = [self.line_2, self.line_3, (self.line_4_number.to_s+' '+self.line_4_street.to_s).strip, self.line_5, (self.line_6_code.to_s+" "+self.line_6_city.to_s).strip, (self.country.blank? ? '' : I18n.t("countries.#{self.country}"))].compact
    lines.delete ""
    self.address = lines.join(", ")

    self.website = "http://"+self.website unless self.website.blank? or self.website.match /^.+p.*\/\//
  end

  # Each contact have a distinct code for a precise company.  
  def before_validation_on_create    
    unless self.code
      self.code = 'AAAA'
      while Contact.count(:conditions=>["entity_id=? AND company_id=? AND code=?", self.entity_id, self.company_id, self.code])>0 do
        self.code.succ!
      end
      self.active = true
      self.started_at = Time.now
    end
  end

  # A contact can not be modified.
  # Therefore a contact is created for each update
  def before_update
    self.stopped_at = Time.now
    Contact.create!(self.attributes.merge({:code=>self.code, :active=>true, :started_at=>self.stopped_at, :stopped_at=>nil, :company_id=>self.company_id, :entity_id=>self.entity_id, :norm_id=>self.norm_id})) if self.active
    self.active = false
  end
  
  #  def validate_on_update 
  #    errors.add_to_base tc(:error_modify_contact) if self.active
  #  end

  # This method 
  #  def upgrade(values)
  #    now = Time.now
  #    self.update_attributes({:active=>false, :stopped_at=>now})
  #    contact = Contact.create!(values.merge!({:code=>self.code, :active=>true, :started_at=>now, :company_id=>self.company_id, :entity_id=>self.entity_id, :norm_id=>self.norm_id}))
  #    contact
  #  end
  
end
