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
# == Table: cultivable_zones
#
#  codes                  :jsonb
#  created_at             :datetime         not null
#  creator_id             :integer
#  custom_fields          :jsonb
#  description            :text
#  farmer_id              :integer
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string           not null
#  owner_id               :integer
#  production_system_name :string
#  shape                  :geometry({:srid=>4326, :type=>"multi_polygon"}) not null
#  soil_nature            :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#  uuid                   :uuid
#  work_number            :string           not null
#

class CultivableZone < Ekylibre::Record::Base
  include Attachable
  include Customizable
  refers_to :production_system
  refers_to :soil_nature
  belongs_to :farmer, class_name: 'Entity'
  belongs_to :owner, class_name: 'Entity'
  has_many :activity_productions, foreign_key: :cultivable_zone_id
  has_many :activities, through: :activity_productions
  has_many :current_activity_productions, -> { current }, foreign_key: :cultivable_zone_id, class_name: 'ActivityProduction'
  has_many :current_supports, through: :current_activity_productions, source: :support
  has_many :supports, through: :activity_productions
  has_geometry :shape, type: :multi_polygon
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, :work_number, presence: true, length: { maximum: 500 }
  validates :shape, presence: true
  # ]VALIDATORS]
  validates :uuid, presence: true

  scope :of_current_activity_productions, -> { where(id: ActivityProduction.select(:cultivable_zone_id).current) }
  scope :of_campaign, ->(campaign) { where(id: ActivityProduction.select(:cultivable_zone_id).of_campaign(campaign)) }
  scope :of_production_system, ->(production_system) { where('production_system_name IS NULL OR production_system_name = ? OR production_system_name = ?', '', production_system) }

  protect on: :destroy do
    activity_productions.any?
  end

  before_validation do
    self.uuid ||= UUIDTools::UUID.random_create.to_s
    self.work_number ||= UUIDTools::UUID.parse(self.uuid).to_i.to_s(36)
  end

  alias net_surface_area shape_area

  def shape_svg
    shape.to_svg(srid: 2154)
  end

  # get the first object with variety 'plant', availables
  def current_cultivations(at = Time.zone.now)
    Plant.contained_by(current_supports, at)
  end

  # Returns last created islet number from cap statements
  def cap_number
    islets = CapIslet.shape_intersecting(shape).order(id: :desc)
    return islets.first.islet_number if islets.any?
    nil
  end

  def city_name
    islets = CapIslet.shape_intersecting(shape).order(id: :desc)
    return islets.first.city_name if islets.any?
    nil
  end

  after_commit do
    activity_productions.each(&:update_names)
    Ekylibre::Hook.publish(:cultivable_zone_change, cultivable_zone_id: id)
  end

  after_destroy do
    Ekylibre::Hook.publish(:cultivable_zone_destroy, cultivable_zone_id: id)
  end
end
