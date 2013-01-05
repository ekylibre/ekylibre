# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: entity_addresses
#
#  by_default       :boolean          not null
#  canal            :string(16)       not null
#  code             :string(4)        
#  coordinate       :string(511)      not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  deleted_at       :datetime         
#  entity_id        :integer          not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mail_area_id     :integer          
#  mail_auto_update :boolean          not null
#  mail_country     :string(2)        
#  mail_geolocation :spatial({:srid=> 
#  mail_line_1      :string(255)      
#  mail_line_2      :string(255)      
#  mail_line_3      :string(255)      
#  mail_line_4      :string(255)      
#  mail_line_5      :string(255)      
#  mail_line_6      :string(255)      
#  name             :string(255)      
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class EntityAddress < CompanyRecord
  attr_readonly   :entity_id, :name, :code,       :canal, :coordinate, :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_line_6, :mail_country
  attr_accessible :entity_id, :name, :by_default, :canal, :coordinate, :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_line_6, :mail_country
  belongs_to :mail_area, :class_name => "Area"
  belongs_to :entity
  has_many :incoming_deliveries
  has_many :outgoing_deliveries
  has_many :purchases
  has_many :sales
  has_many :subscriptions
  has_many :warehouses
  enumerize :canal, :in => %w(mail email phone mobile fax website), :default => :email, :predicates => true

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :mail_country, :allow_nil => true, :maximum => 2
  validates_length_of :code, :allow_nil => true, :maximum => 4
  validates_length_of :canal, :allow_nil => true, :maximum => 16
  validates_length_of :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_line_6, :name, :allow_nil => true, :maximum => 255
  validates_length_of :coordinate, :allow_nil => true, :maximum => 511
  validates_inclusion_of :by_default, :mail_auto_update, :in => [true, false]
  validates_presence_of :canal, :coordinate, :entity
  #]VALIDATORS]
  validates_format_of :coordinate, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :if => lambda{|a| a.email?}
  validates_inclusion_of :canal, :in => self.canal.values

  default_scope -> { where("deleted_at IS NULL") }

  # Defines test and scope methods for all canals
  self.canal.values.each do |canal|
    scope canal, -> {where(canal: canal)}
    scope "own_#{canal.to_s.pluralize}", -> { where("canal = ? AND entity_id = ?", canal, Entity.of_company.id) }
  end


  before_validation do
    if self.entity
      self.by_default = true if self.entity.addresses.where(:canal => self.canal).count.zero?
    end
    self.coordinate.strip! if self.coordinate.is_a?(String)
    if self.mail?
      if self.mail_line_6
        self.mail_line_6 = self.mail_line_6.to_s.gsub(/\s+/,' ').strip
        if self.mail_line_6.blank?
          self.mail_area_id = nil
        else
          self.mail_area = Area.where("LOWER(" + self.class.connection.trim("name") + ") LIKE ?", self.mail_line_6.lower).first
          self.mail_area = Area.create!(:name => self.mail_line_6, :country => self.mail_country) if self.mail_area.nil?
        end
      end
      self.mail_line_1 = self.entity.full_name if self.mail_line_1.blank?
      self.mail_auto_update = (self.entity.full_name == self.mail_line_1 ? true : false)
      self.coordinate = self.mail_lines
    elsif self.website?
      self.coordinate = "http://"+self.coordinate unless self.coordinate.match(/^.+p.*\/\//)
    end
  end

  # Each contact have a distinct code
  before_validation(:on => :create) do
    if self.code.blank?
      self.code = 'AAAA'
      while self.class.count(:conditions => ["entity_id = ? AND canal = ? AND code = ?", self.entity_id, self.canal, self.code]) > 0 do
        self.code.succ!
      end
    end
  end

  after_save do
      if self.by_default
      self.class.update_all({:by_default => false}, ["entity_id = ? AND canal = ? AND id != ?", self.entity_id, self.canal, self.id])
    end
  end


  def update # _without_callbacks
    # raise Exception.new "UPDAAAAAAAAAAAATE"
    current_time = Time.now
    stamper = self.class.stamper_class.stamper rescue nil
    # raise stamper.inspect unless stamper.nil?
    stamper_id = stamper.id if stamper.is_a? Entity
    nc = self.class.new
    for attr, val in self.attributes.merge(:created_at => current_time, :updated_at => current_time, :creator_id => stamper_id, :updater_id => stamper_id).delete_if{|k,v| k.to_s == "id"}
      nc.send("#{attr}=", val)
    end
    nc.save!
    self.class.update_all({:deleted_at => current_time}, {:id => self.id})
    return nc
  end

  def destroy # _without_callbacks
    unless new_record?
      self.class.update_all({:deleted_at => Time.now}, {:id => self.id})
    end
  end

  def self.exportable_columns
    return self.content_columns.delete_if{|c| [:deleted_at, :closed_on, :lock_version, :code, :created_at, :updated_at].include?(c.name.to_sym)}
  end

  def label
    self.entity.code + ". " + self.coordinate
  end

  def mail_line_6_code
    self.mail_area.postcode if self.mail_area
  end

  def mail_line_6_code=(value)
    self.mail_line_6 = (value.to_s+" "+self.mail_line_6.to_s).strip
  end

  def mail_mail_line_6_city
    self.mail_area.city if self.mail_area
  end

  def mail_line_6_city=(value)
    self.mail_line_6 = (self.mail_line_6.to_s+" "+value.to_s).strip
  end

  def mail_lines(options = {})
    options = {:separator => ', ', :with_city => true, :with_country => true}.merge(options)
    lines = [self.mail_line_1, self.mail_line_2, self.mail_line_3, self.mail_line_4, self.mail_line_5]
    lines << self.mail_line_6.to_s if options[:with_city]
    lines << (self.mail_country.blank? ? '' : I18n.t("countries.#{self.mail_country}")) if options[:with_country]
    lines = lines.compact.collect{|x| x.gsub(options[:separator], ' ').gsub(/\ +/, ' ')}
    lines.delete ""
    return lines.join(options[:separator])
  end

  def mail_coordinate
    return self.mail_lines(:separator => "\r\n")
  end

end
