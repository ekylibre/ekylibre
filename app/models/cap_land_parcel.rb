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
# == Table: cap_land_parcels
#
#  cap_islet_id                :integer          not null
#  created_at                  :datetime         not null
#  creator_id                  :integer
#  id                          :integer          not null, primary key
#  land_parcel_number          :string           not null
#  lock_version                :integer          default(0), not null
#  main_crop_code              :string           not null
#  main_crop_commercialisation :boolean          default(FALSE), not null
#  main_crop_precision         :string
#  main_crop_seed_production   :boolean          default(FALSE), not null
#  shape                       :geometry({:srid=>4326, :type=>"geometry"}) not null
#  support_id                  :integer
#  updated_at                  :datetime         not null
#  updater_id                  :integer
#

class CapLandParcel < Ekylibre::Record::Base
  belongs_to :cap_islet, class_name: 'CapIslet'
  belongs_to :support, class_name: 'ProductionSupport'
  has_one :cap_statement, through: :cap_islet
  has_one :campaign, through: :cap_statement
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :main_crop_commercialisation, :main_crop_seed_production, in: [true, false]
  validates_presence_of :cap_islet, :land_parcel_number, :main_crop_code, :shape
  # ]VALIDATORS]

  scope :of_campaign, lambda { |*campaigns|
    joins(:cap_islet).merge(CapIslet.of_campaign(*campaigns))
  }

  def to_geom
    return geom = ::Charta::Geometry.new(shape).transform(:WGS84) if shape
  end

  def label_area(unit = :hectare)
    value = to_geom.area.to_d(unit).round(3).l
    unit = Nomen::Unit[unit].human_name
    "#{value} #{unit}"
  end

  def net_surface_area(unit = :hectare)
    value = to_geom.area.to_d(unit).round(3)
  end
end
