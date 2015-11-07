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
# == Table: cap_islets
#
#  cap_statement_id :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  islet_number     :string           not null
#  lock_version     :integer          default(0), not null
#  shape            :geometry({:srid=>4326, :type=>"geometry"}) not null
#  town_number      :string           not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class CapIslet < Ekylibre::Record::Base
  belongs_to :cap_statement
  has_many :cap_land_parcels, class_name: 'CapLandParcel', dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :cap_statement, :islet_number, :shape, :town_number
  # ]VALIDATORS]
  delegate :harvest_year, to: :cap_statement, prefix: false
  delegate :pacage_number, to: :cap_statement, prefix: false

  scope :of_campaign, lambda { |*campaigns|
    joins(:cap_statement).merge(CapStatement.of_campaign(*campaigns))
  }

  def to_geom
    return geom = ::Charta::Geometry.new(shape).transform(:WGS84) if shape
  end

  def label_area(unit = :hectare)
    value = to_geom.area.to_d(unit).round(3).l
    unit = Nomen::Unit[unit].human_name
    return "#{value} #{unit}"
  end

  def net_surface_area(unit = :hectare)
    value = to_geom.area.to_d(unit).round(3)
  end

end
