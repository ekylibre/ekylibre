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
# == Table: cvi_cadastral_plants
#
#  area_unit                       :string
#  area_value                      :decimal(19, 4)
#  cadastral_ref_updated           :boolean          default(FALSE)
#  created_at                      :datetime         not null
#  creator_id                      :integer
#  cvi_cultivable_zone_id          :integer
#  cvi_statement_id                :integer
#  designation_of_origin_id        :integer
#  id                              :integer          not null, primary key
#  inter_row_distance_unit         :string
#  inter_row_distance_value        :decimal(19, 4)
#  inter_vine_plant_distance_unit  :string
#  inter_vine_plant_distance_value :decimal(19, 4)
#  land_modification_date          :date
#  land_parcel_id                  :string
#  land_parcel_number              :string
#  lock_version                    :integer          default(0), not null
#  planting_campaign               :string
#  rootstock_id                    :string
#  section                         :string           not null
#  state                           :string           not null
#  type_of_occupancy               :string
#  updated_at                      :datetime         not null
#  updater_id                      :integer
#  vine_variety_id                 :string
#  work_number                     :string           not null
#
class CviCadastralPlant < ApplicationRecord
  composed_of :area, class_name: 'Measure', mapping: [%w[area_value to_d], %w[area_unit unit]]
  composed_of :inter_row_distance, class_name: 'Measure', mapping: [%w[inter_row_distance_value to_d], %w[inter_row_distance_unit unit]]
  composed_of :inter_vine_plant_distance, class_name: 'Measure', mapping: [%w[inter_vine_plant_distance_value to_d], %w[inter_vine_plant_distance_unit unit]]

  enumerize :state, in: %i[planted removed_with_authorization], predicates: true
  enumerize :type_of_occupancy, in: %i[tenant_farming owner], predicates: true

  belongs_to :cvi_cultivable_zone
  belongs_to :cvi_statement
  belongs_to :land_parcel, class_name: 'RegisteredCadastralParcel', foreign_key: :land_parcel_id, inverse_of: :cvi_cadastral_plants
  belongs_to :designation_of_origin, class_name: 'RegisteredQualityAndOriginSign', foreign_key: :designation_of_origin_id, inverse_of: :cvi_cadastral_plants
  belongs_to :vine_variety, class_name: 'RegisteredVineVariety', foreign_key: :vine_variety_id
  belongs_to :rootstock, class_name: 'RegisteredVineVariety', foreign_key: :rootstock_id
  has_one :location, as: :localizable, dependent: :destroy
  has_one :registered_postal_zone, through: :location
  has_many :cvi_cadastral_plant_cvi_land_parcels, dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :area_unit, :inter_row_distance_unit, :inter_vine_plant_distance_unit, :land_parcel_number, :planting_campaign, length: { maximum: 500 }, allow_blank: true
  validates :area_value, :inter_row_distance_value, :inter_vine_plant_distance_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :cadastral_ref_updated, inclusion: { in: [true, false] }, allow_blank: true
  validates :land_modification_date, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years }, type: :date }, allow_blank: true
  validates :section, :work_number, presence: true, length: { maximum: 500 }
  validates :state, presence: true
  # ]VALIDATORS]
  validates_presence_of :land_parcel, on: :update, message: :cannot_find_land_parcel

  delegate :registered_postal_zone_id, to: :location
  delegate :shape, to: :land_parcel

  accepts_nested_attributes_for :location

  def cadastral_reference
    base = section + work_number
    if land_parcel_number.blank?
      base
    else
      base + '-' + land_parcel_number
    end
  end

  def updated?
    created_at != updated_at
  end
end
