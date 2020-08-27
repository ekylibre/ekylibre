# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: entity_addresses
#
#  by_default          :boolean          default(FALSE), not null
#  canal               :string           not null
#  coordinate          :string           not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  deleted_at          :datetime
#  entity_id           :integer          not null
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  mail_auto_update    :boolean          default(FALSE), not null
#  mail_country        :string
#  mail_geolocation    :geometry({:srid=>4326, :type=>"st_point"})
#  mail_line_1         :string
#  mail_line_2         :string
#  mail_line_3         :string
#  mail_line_4         :string
#  mail_line_5         :string
#  mail_line_6         :string
#  mail_postal_zone_id :integer
#  name                :string
#  thread              :string
#  updated_at          :datetime         not null
#  updater_id          :integer
#

class EntityAddress < Ekylibre::Record::Base
  attr_readonly :entity_id
  refers_to :mail_country, class_name: 'Country'
  belongs_to :mail_postal_zone, class_name: 'PostalZone'
  belongs_to :entity, inverse_of: :addresses
  has_many :buildings, foreign_key: :address_id
  has_many :parcels, foreign_key: :address_id, dependent: :restrict_with_exception
  has_many :purchases, foreign_key: :delivery_address_id
  has_many :sales, foreign_key: :address_id
  has_many :subscriptions, foreign_key: :address_id
  enumerize :canal, in: %i[mail email phone mobile fax website], default: :email, predicates: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :by_default, :mail_auto_update, inclusion: { in: [true, false] }
  validates :canal, :entity, presence: true
  validates :coordinate, presence: true, length: { maximum: 500 }
  validates :deleted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_line_6, :name, :thread, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :mail_country, length: { allow_nil: true, maximum: 2 }
  validates :canal, length: { allow_nil: true, maximum: 20 }
  validates :coordinate, length: { allow_nil: true, maximum: 500 }
  validates :coordinate, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: :email? }
  validates :canal, inclusion: { in: canal.values }
  validates :mail_country, presence: { if: :mail? }

  selects_among_all scope: %i[entity_id canal], subset: :actives

  # Use unscoped to get all historic
  default_scope -> { actives }
  scope :actives, -> { where(deleted_at: nil).order(:coordinate) }

  # Defines test and scope methods for.all canals
  canal.values.each do |canal|
    scope canal.to_s.pluralize, -> { where(canal: canal.to_s) }
    scope "own_#{canal.to_s.pluralize}", -> { where(canal: canal.to_s, entity_id: Entity.of_company.id) }
  end

  before_validation do
    if coordinate.is_a?(String)
      coordinate.strip!
      coordinate.downcase!
    end
    if mail?
      self.mail_country = Preference[:country] if mail_country.blank?
      if mail_line_6
        self.mail_line_6 = mail_line_6.to_s.gsub(/\s+/, ' ').strip
        if mail_line_6.blank?
          self.mail_postal_zone_id = nil
        else
          unless self.mail_postal_zone = PostalZone.find_by('LOWER(TRIM(name)) LIKE ?', mail_line_6.lower)
            self.mail_postal_zone = PostalZone.create!(name: mail_line_6, country: mail_country)
          end
        end
      end
      if entity
        self.mail_line_1 = entity.full_name if mail_line_1.blank?
        self.mail_auto_update = (entity.full_name == mail_line_1)
      end
      self.coordinate = mail_lines
    elsif website?
      self.coordinate = 'http://' + coordinate unless coordinate =~ /^.+p.*\/\//
    end
  end

  # Each address have a distinct thread
  before_validation(on: :create) do
    if thread.blank?
      self.thread = 'AAAA'
      while self.class.where('entity_id = ? AND canal = ? AND thread = ?', entity_id, canal, thread).count > 0
        thread.succ!
      end
    end
  end

  def update # _without_.allbacks
    # raise StandardError.new "UPDAAAAAAAAAAAATE"
    current_time = Time.zone.now
    stamper = begin
                self.class.stamper_class.stamper
              rescue
                nil
              end
    # raise stamper.inspect unless stamper.nil?
    stamper_id = stamper.id if stamper.is_a? Entity
    nc = self.class.new
    for attr, val in attributes.merge(created_at: current_time, updated_at: current_time, creator_id: stamper_id, updater_id: stamper_id).delete_if { |k, _v| k.to_s == 'id' }
      nc.send("#{attr}=", val)
    end
    nc.save!
    self.class.where(id: id).update_all(deleted_at: current_time)
    nc
  end

  def destroy # _without_.allbacks
    self.class.where(id: id).update_all(deleted_at: Time.zone.now) unless new_record?
  end

  def self.exportable_columns
    content_columns.delete_if { |c| %i[deleted_at closed_at lock_version thread created_at updated_at].include?(c.name.to_sym) }
  end

  def label
    entity.number + '. ' + coordinate
  end

  def mail_line_6_code
    mail_postal_zone.postal_code if mail_postal_zone
  end
  alias mail_postal_code mail_line_6_code

  def mail_line_6_code=(value)
    self.mail_line_6 = (value.to_s + ' ' + mail_line_6.to_s).strip
  end

  def mail_mail_line_6_city
    mail_postal_zone.city if mail_postal_zone
  end

  def mail_line_6_city=(value)
    self.mail_line_6 = (mail_line_6.to_s + ' ' + value.to_s).strip
  end

  def mail_lines(options = {})
    options = { separator: ', ', with_city: true, with_country: true }.merge(options)
    lines = []
    lines << mail_line_1 unless options[:without] == :line_1
    lines += [mail_line_2, mail_line_3, mail_line_4, mail_line_5]
    lines << mail_line_6.to_s if options[:with_city]
    lines << (Nomen::Country[mail_country] ? Nomen::Country[mail_country].human_name : '') if options[:with_country]
    lines = lines.compact.collect { |x| x.gsub(options[:separator], ' ').gsub(/\ +/, ' ') }
    lines.delete ''
    lines.join(options[:separator])
  end

  def mail_coordinate
    mail_lines(separator: "\r\n")
  end
end
