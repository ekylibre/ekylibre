# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  created_at                       :datetime         not null
#  creator_id                       :integer
#  custom_fields                    :jsonb
#  description                      :text
#  id                               :integer          not null, primary key
#  lock_version                     :integer          default(0), not null
#  name                             :string           not null
#  production_system_reference_name :string
#  shape                            :geometry({:srid=>4326, :type=>"multi_polygon"}) not null
#  updated_at                       :datetime         not null
#  updater_id                       :integer
#  uuid                             :uuid
#  work_number                      :string           not null
#

class CultivableZone < Ekylibre::Record::Base
  include Attachable
  include Customizable
  has_many :activity_productions, foreign_key: :cultivable_zone_id
  has_many :activities, through: :activity_productions
  has_many :current_activity_productions, -> { current }, foreign_key: :cultivable_zone_id, class_name: 'ActivityProduction'
  has_many :current_supports, through: :current_activity_productions, source: :support
  has_many :supports, through: :activity_productions
  has_geometry :shape, type: :multi_polygon
  refers_to :production_system_reference_name, class_name: 'ProductionSystem'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :name, :shape, :work_number
  # ]VALIDATORS]
  validates_presence_of :uuid

  scope :of_current_activity_productions, -> { where(id: ActivityProduction.select(:cultivable_zone_id).current) }
  scope :of_campaign, ->(campaign) { where(id: ActivityProduction.select(:cultivable_zone_id).of_campaign(campaign)) }

  before_validation do
    self.uuid ||= UUIDTools::UUID.random_create.to_s
    self.work_number ||= UUIDTools::UUID.parse(self.uuid).to_i.to_s(36)
  end

  alias net_surface_area shape_area

  # get the first object with variety 'plant', availables
  def current_cultivations
    Plant.contained_by(current_supports)
  end

  # Returns last created islet number from cap statements
  def cap_number
    islets = CapIslet.shape_matching(shape).order(id: :desc)
    return islets.first.islet_number if islets.any?
    nil
  end
end
