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
#  shape                       :geometry({:srid=>4326, :type=>"multi_polygon"}) not null
#  support_id                  :integer
#  updated_at                  :datetime         not null
#  updater_id                  :integer
#

class CapLandParcel < Ekylibre::Record::Base
  belongs_to :activity_production, foreign_key: :support_id
  belongs_to :cap_islet
  belongs_to :islet, class_name: 'CapIslet', foreign_key: :cap_islet_id
  has_one :cap_statement, through: :cap_islet
  has_one :campaign, through: :cap_statement
  has_geometry :shape, type: :multi_polygon
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :land_parcel_number, :main_crop_code, presence: true, length: { maximum: 500 }
  validates :main_crop_commercialisation, :main_crop_seed_production, inclusion: { in: [true, false] }
  validates :main_crop_precision, length: { maximum: 500 }, allow_blank: true
  validates :cap_islet, :islet, :shape, presence: true
  # ]VALIDATORS]

  delegate :pacage_number, to: :cap_statement
  delegate :islet_number, to: :cap_islet
  delegate :name, to: :campaign, prefix: true

  scope :of_campaign, lambda { |*campaigns|
    where(cap_islet_id: CapIslet.of_campaign(*campaigns))
  }

  alias net_surface_area shape_area
end
