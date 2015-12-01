# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: cultivable_zones
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  shape        :geometry({:srid=>4326, :type=>"geometry"}) not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#  uuid         :uuid
#  work_number  :string           not null
#

class CultivableZone < Ekylibre::Record::Base
  include Attachable
  has_many :activity_productions, foreign_key: :cultivable_zone_id
  has_many :activities, through: :activity_productions
  has_many :current_activity_productions, -> { current }, foreign_key: :cultivable_zone_id, class_name: 'ActivityProduction'
  has_many :current_supports, through: :current_activity_productions, source: :support
  has_many :supports, through: :activity_productions

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :name, :shape, :work_number
  # ]VALIDATORS]
  validates_presence_of :uuid

  scope :of_current_activity_productions, -> { where(id: ActivityProduction.select(:cultivable_zone_id).current) }
  scope :of_campaign, ->(campaign) { where(id: ActivityProduction.select(:cultivable_zone_id).of_campaign(campaign)) }
  scope :covers_shape, lambda { |shape|
    where('ST_Covers(shape, ST_GeomFromEWKT(?))', ::Charta::Geometry.new(shape).to_ewkt)
  }

  before_validation do
    self.uuid ||= UUIDTools::UUID.random_create.to_s
    self.work_number ||= UUIDTools::UUID.parse(self.uuid).to_i.to_s(36)
  end

  def to_geom
    ::Charta::Geometry.new(shape)
  end

  # Computes net surface area of shape
  def net_surface_area(unit = :hectare)
    to_geom.area.in(unit).round(3)
  end

  # get the first object with variety 'plant', availables
  def current_cultivations
    Plant.contained_by(current_supports)
  end

  def shape=(value)
    if value.is_a?(String) && value =~ /\A\{.*\}\z/
      value = Charta::Geometry.new(JSON.parse(value).to_json, :WGS84).to_rgeo
    elsif !value.blank?
      value = Charta::Geometry.new(value).to_rgeo
    end
    self['shape'] = value
  end
end
