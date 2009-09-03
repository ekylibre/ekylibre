# == Schema Information
#
# Table name: contacts
#
#  active        :boolean       not null
#  address       :string(280)   
#  area_id       :integer       
#  closed_on     :date          
#  code          :string(4)     
#  company_id    :integer       not null
#  country       :string(2)     
#  created_at    :datetime      not null
#  creator_id    :integer       
#  default       :boolean       not null
#  deleted       :boolean       not null
#  email         :string(255)   
#  entity_id     :integer       not null
#  fax           :string(32)    
#  id            :integer       not null, primary key
#  latitude      :float         
#  line_2        :string(38)    
#  line_3        :string(38)    
#  line_4_number :string(38)    
#  line_4_street :string(38)    
#  line_5        :string(38)    
#  line_6        :string(255)   
#  lock_version  :integer       default(0), not null
#  longitude     :float         
#  mobile        :string(32)    
#  norm_id       :integer       not null
#  phone         :string(32)    
#  started_at    :datetime      
#  stopped_at    :datetime      
#  updated_at    :datetime      not null
#  updater_id    :integer       
#  website       :string(255)   
#

class Contact < ActiveRecord::Base
  belongs_to :area
  belongs_to :company
  belongs_to :entity
  belongs_to :norm, :class_name=>AddressNorm.name
  has_many :deliveries
  has_many :invoices
  has_many :purchase_orders
  has_many :stock_locations
  has_many :subscriptions

  # belongs_to :element, :polymorphic=> true
  attr_readonly :entity_id, :company_id, :norm_id
  attr_readonly :name, :code, :line_2, :line_3, :line_4_number, :line_4_street, :line_5, :line_6, :address, :phone, :fax, :mobile, :email, :website

  def before_validation
    if self.entity
      self.default = true if self.entity.contacts.size <= 0
    end
    if self.line_6
      self.line_6 = self.line_6.gsub(/\s+/,' ').strip
      if self.line_6.blank?
        self.area_id = nil
      else
        self.area = self.company.areas.find(:first, :conditions=>["LOWER(TRIM(name)) LIKE ?", self.line_6.lower])
        self.area = self.company.areas.create!(:name=>self.line_6, :country=>self.country) if self.area.nil?
      end
    end
    Contact.update_all({:default=>false}, ["entity_id=? AND company_id=? AND id!=?", self.entity_id,self.company_id, self.id||0]) if self.default
    self.address = self.lines
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
    if self.active
      Contact.create!(self.attributes.merge({:code=>self.code, :active=>true, :started_at=>self.stopped_at, :stopped_at=>nil, :company_id=>self.company_id, :entity_id=>self.entity_id, :norm_id=>self.norm_id}))
    end
    self.active = false
    true
  end  

  def label
    self.entity.code+". "+self.address
  end

  def line_6_code
    self.area.postcode if self.area
  end

  def line_6_city
    self.area.city if self.area
  end

  def lines(sep=', ', with_city=true, with_country=true)
    lines = [self.line_2, self.line_3, (self.line_4_number.to_s+' '+self.line_4_street.to_s).strip, self.line_5]
    lines << self.line_6.to_s if with_city
    lines << (self.country.blank? ? '' : I18n.t("countries.#{self.country}")) if with_country
    lines = lines.compact.collect{|x| x.gsub(sep,' ')}
    lines.delete ""
    lines.join(sep)
  end
  
end
