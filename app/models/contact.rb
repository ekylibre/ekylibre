# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: contacts
#
#  address      :string(280)      
#  area_id      :integer          
#  by_default   :boolean          not null
#  code         :string(4)        
#  company_id   :integer          not null
#  country      :string(2)        
#  created_at   :datetime         not null
#  creator_id   :integer          
#  deleted_at   :datetime         
#  email        :string(255)      
#  entity_id    :integer          not null
#  fax          :string(32)       
#  id           :integer          not null, primary key
#  latitude     :float            
#  line_2       :string(38)       
#  line_3       :string(38)       
#  line_4       :string(48)       
#  line_5       :string(38)       
#  line_6       :string(255)      
#  lock_version :integer          default(0), not null
#  longitude    :float            
#  mobile       :string(32)       
#  phone        :string(32)       
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  website      :string(255)      
#


class Contact < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :latitude, :longitude, :allow_nil => true
  validates_length_of :country, :allow_nil => true, :maximum => 2
  validates_length_of :code, :allow_nil => true, :maximum => 4
  validates_length_of :fax, :mobile, :phone, :allow_nil => true, :maximum => 32
  validates_length_of :line_2, :line_3, :line_5, :allow_nil => true, :maximum => 38
  validates_length_of :line_4, :allow_nil => true, :maximum => 48
  validates_length_of :email, :line_6, :website, :allow_nil => true, :maximum => 255
  validates_length_of :address, :allow_nil => true, :maximum => 280
  validates_inclusion_of :by_default, :in => [true, false]
  validates_presence_of :company, :entity
  #]VALIDATORS]
  attr_readonly :entity_id, :company_id
  attr_readonly :name, :code, :line_2, :line_3, :line_4, :line_5, :line_6, :address, :phone, :fax, :mobile, :email, :website
  belongs_to :area
  belongs_to :company
  belongs_to :entity
  has_many :outgoing_deliveries
  has_many :purchases
  has_many :sales
  has_many :subscriptions
  has_many :warehouses

  validates_format_of :email, :with=>/^[^\s]+\@[^\s]+$/, :if=>lambda{|c| !c.email.blank?}

  before_validation do
    if self.entity
      self.by_default = true if self.entity.contacts.size <= 0
      self.company_id = self.entity.company_id
    end
    self.email.strip! if self.email.is_a? String
    if self.line_6
      self.line_6 = self.line_6.gsub(/\s+/,' ').strip
      if self.line_6.blank?
        self.area_id = nil
      else
        self.area = self.company.areas.find(:first, :conditions=>["LOWER("+self.class.connection.trim("name")+") LIKE ?", self.line_6.lower])
        self.area = self.company.areas.create!(:name=>self.line_6, :country=>self.country) if self.area.nil?
      end
    end
    Contact.update_all({:by_default=>false}, ["entity_id=? AND company_id=? AND id!=?", self.entity_id,self.company_id, self.id||0]) if self.by_default
    self.address = self.lines
    self.website = "http://"+self.website unless self.website.blank? or self.website.match /^.+p.*\/\//
  end

  # Each contact have a distinct code for a precise company.  
  before_validation(:on=>:create) do    
    if self.code.blank?
      self.code = 'AAAA'
      while Contact.count(:conditions=>["entity_id=? AND company_id=? AND code=?", self.entity_id, self.company_id, self.code]) > 0 do
        self.code.succ!
      end
    end
  end

  def update # _without_callbacks
    # raise Exception.new "UPDAAAAAAAAAAAATE"
    current_time = Time.now
    stamper = self.class.stamper_class.stamper rescue nil
    # raise stamper.inspect unless stamper.nil?
    stamper_id = stamper.id if stamper.is_a? User
    nc = self.class.create!(self.attributes.delete_if{|k,v| [:company_id].include?(k.to_sym)}.merge(:created_at=>current_time, :updated_at=>current_time, :creator_id=>stamper_id, :updater_id=>stamper_id))
    self.class.update_all({:deleted_at=>current_time}, {:id=>self.id})
    return nc
  end

  def destroy # _without_callbacks
    unless new_record?
      self.class.update_all({:deleted_at=>Time.now}, {:id=>self.id})
    end
  end

  def self.exportable_columns
    self.content_columns.delete_if{|c| [:active, :started_at, :stopped_at, :closed_on, :deleted, :latitude, :longitude, :lock_version, :code, :created_at, :updated_at].include?(c.name.to_sym)}
  end

  def label
    self.entity.code+". "+self.address
  end

  def line_6_code
    self.area.postcode if self.area
  end

  def line_6_code=(value)
    self.line_6 = (value.to_s+" "+self.line_6.to_s).strip
  end

  def line_6_city
    self.area.city if self.area
  end

  def line_6_city=(value)
    self.line_6 = (self.line_6.to_s+" "+value.to_s).strip
  end

  def lines(sep=', ', with_city=true, with_country=true)
    lines = [self.line_2, self.line_3, self.line_4, self.line_5]
    lines << self.line_6.to_s if with_city
    lines << (self.country.blank? ? '' : I18n.t("countries.#{self.country}")) if with_country
    lines = lines.compact.collect{|x| x.gsub(sep,' ')}
    lines.delete ""
    lines.join(sep)
  end
 
  def print_address
    a = self.entity.full_name+"\n"
    a += self.address.gsub(/\s*\,\s*/, "\n")
    a
  end

  def mail
    return [self.entity.full_name, self.line_2, self.line_3, self.line_4, self.line_5, self.line_6].delete_if(&:blank?).collect do |l|
        l.gsub(";", ",")
    end.join(";")
  end

end
