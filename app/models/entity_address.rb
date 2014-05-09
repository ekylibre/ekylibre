# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  by_default          :boolean          not null
#  canal               :string(20)       not null
#  coordinate          :string(500)      not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  deleted_at          :datetime
#  entity_id           :integer          not null
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  mail_auto_update    :boolean          not null
#  mail_country        :string(2)
#  mail_geolocation    :spatial({:srid=>
#  mail_line_1         :string(255)
#  mail_line_2         :string(255)
#  mail_line_3         :string(255)
#  mail_line_4         :string(255)
#  mail_line_5         :string(255)
#  mail_line_6         :string(255)
#  mail_postal_zone_id :integer
#  name                :string(255)
#  thread              :string(10)
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class EntityAddress < Ekylibre::Record::Base
  attr_readonly :entity_id
  belongs_to :mail_postal_zone, class_name: "PostalZone"
  belongs_to :entity, inverse_of: :addresses
  has_many :incoming_deliveries
  has_many :outgoing_deliveries
  has_many :purchases
  has_many :sales
  has_many :subscriptions
  has_many :buildings
  enumerize :canal, in: [:mail, :email, :phone, :mobile, :fax, :website], default: :email, predicates: true
  # enumerize :country, in: Nomen::Countries.all

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :mail_country, allow_nil: true, maximum: 2
  validates_length_of :thread, allow_nil: true, maximum: 10
  validates_length_of :canal, allow_nil: true, maximum: 20
  validates_length_of :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_line_6, :name, allow_nil: true, maximum: 255
  validates_length_of :coordinate, allow_nil: true, maximum: 500
  validates_inclusion_of :by_default, :mail_auto_update, in: [true, false]
  validates_presence_of :canal, :coordinate, :entity
  #]VALIDATORS]
  validates_format_of :coordinate, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: :email?
  validates_inclusion_of :canal, in: self.canal.values
  validates_presence_of :mail_country, if: :mail?


  selects_among_all scope: [:entity_id, :canal]

  # Use unscoped to get all historic
  default_scope -> { where("deleted_at IS NULL").order(:coordinate) }

  # Defines test and scope methods for.all canals
  self.canal.values.each do |canal|
    scope canal.to_s.pluralize, -> { where(canal: canal.to_s) }
    scope "own_#{canal.to_s.pluralize}", -> { where(canal: canal.to_s, entity_id: Entity.of_company.id) }
  end


  before_validation do
    if self.coordinate.is_a?(String)
      self.coordinate.strip!
      self.coordinate.downcase!
    end
    if self.mail?
      self.mail_country = Preference[:country] if self.mail_country.blank?
      if self.mail_line_6
        self.mail_line_6 = self.mail_line_6.to_s.gsub(/\s+/,' ').strip
        if self.mail_line_6.blank?
          self.mail_postal_zone_id = nil
        else
          unless self.mail_postal_zone = PostalZone.where("LOWER(TRIM(name)) LIKE ?", self.mail_line_6.lower).first
            self.mail_postal_zone = PostalZone.create!(name: self.mail_line_6, country: self.mail_country)
          end
        end
      end
      self.mail_line_1 = self.entity.full_name if self.mail_line_1.blank?
      self.mail_auto_update = (self.entity.full_name == self.mail_line_1 ? true : false)
      self.coordinate = self.mail_lines
    elsif self.website?
      self.coordinate = "http://"+self.coordinate unless self.coordinate.match(/^.+p.*\/\//)
    end
  end

  # Each address have a distinct thread
  before_validation(on: :create) do
    if self.thread.blank?
      self.thread = 'AAAA'
      while self.class.where("entity_id = ? AND canal = ? AND thread = ?", self.entity_id, self.canal, self.thread).count > 0 do
        self.thread.succ!
      end
    end
  end

  def update # _without_.allbacks
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
    self.class.where(:id => self.id).update_all(:deleted_at => current_time)
    return nc
  end

  def destroy # _without_.allbacks
    unless new_record?
      self.class.where(:id => self.id).update_all(:deleted_at => Time.now)
    end
  end

  def self.exportable_columns
    return self.content_columns.delete_if{|c| [:deleted_at, :closed_at, :lock_version, :thread, :created_at, :updated_at].include?(c.name.to_sym)}
  end

  def label
    self.entity.number + ". " + self.coordinate
  end

  def mail_line_6_code
    self.mail_postal_zone.postal_code if self.mail_postal_zone
  end
  alias :mail_postal_code :mail_line_6_code

  def mail_line_6_code=(value)
    self.mail_line_6 = (value.to_s+" "+self.mail_line_6.to_s).strip
  end

  def mail_mail_line_6_city
    self.mail_postal_zone.city if self.mail_postal_zone
  end

  def mail_line_6_city=(value)
    self.mail_line_6 = (self.mail_line_6.to_s+" "+value.to_s).strip
  end

  def mail_lines(options = {})
    options = {:separator => ', ', :with_city => true, :with_country => true}.merge(options)
    lines = [self.mail_line_1, self.mail_line_2, self.mail_line_3, self.mail_line_4, self.mail_line_5]
    lines << self.mail_line_6.to_s if options[:with_city]
    lines << (Nomen::Countries[self.mail_country] ? Nomen::Countries[self.mail_country].human_name : '') if options[:with_country]
    lines = lines.compact.collect{|x| x.gsub(options[:separator], ' ').gsub(/\ +/, ' ')}
    lines.delete ""
    return lines.join(options[:separator])
  end

  def mail_coordinate
    return self.mail_lines(:separator => "\r\n")
  end

end
