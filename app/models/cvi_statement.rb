# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: cvi_statements
#
#  cadastral_plant_count     :integer          default(0)
#  cadastral_sub_plant_count :integer          default(0)
#  campaign_id               :integer
#  created_at                :datetime         not null
#  creator_id                :integer
#  cvi_number                :string           not null
#  declarant                 :string           not null
#  extraction_date           :date             not null
#  farm_name                 :string           not null
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  siret_number              :string           not null
#  state                     :string           not null
#  total_area_unit           :string
#  total_area_value          :decimal(19, 4)
#  updated_at                :datetime         not null
#  updater_id                :integer
#

class CviStatement < ApplicationRecord
  composed_of :total_area, class_name: 'Measure', mapping: [%w[total_area_value to_d], %w[total_area_unit unit]]
  enumerize :state, in: %i[to_convert converted], default: :to_convert, predicates: true

  belongs_to :campaign
  has_many :cvi_cadastral_plants, dependent: :destroy
  has_many :cvi_cultivable_zones, dependent: :destroy
  has_many :cvi_land_parcels, through: :cvi_cultivable_zones

  validates :extraction_date, :siret_number, :farm_name, :declarant, :state, presence: true
  validates :siret_number, siret_format: true
  validates :total_area_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true

  def convertible?
    cvi_cadastral_plants.all?(&:land_parcel_id)
  end
end
