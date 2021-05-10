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
# == Table: cvi_land_parcels
#
#  activity_id                     :integer
#  calculated_area_unit            :string
#  calculated_area_value           :decimal(19, 5)
#  created_at                      :datetime         not null
#  creator_id                      :integer
#  cvi_cultivable_zone_id          :integer
#  declared_area_unit              :string
#  declared_area_value             :decimal(19, 5)
#  designation_of_origin_id        :integer
#  id                              :integer          not null, primary key
#  inter_row_distance_unit         :string
#  inter_row_distance_value        :decimal(19, 4)
#  inter_vine_plant_distance_unit  :string
#  inter_vine_plant_distance_value :decimal(19, 4)
#  land_modification_date          :date
#  lock_version                    :integer          default(0), not null
#  name                            :string           not null
#  planting_campaign               :string
#  rootstock_id                    :string
#  shape                           :polygon          not null
#  state                           :string
#  updated_at                      :datetime         not null
#  updater_id                      :integer
#  vine_variety_id                 :string
#
class CviLandParcel < CviShapedRecord
  composed_of :calculated_area, class_name: 'Measure', mapping: [%w[calculated_area_value to_d], %w[calculated_area_unit unit]]
  composed_of :declared_area, class_name: 'Measure', mapping: [%w[declared_area_value to_d], %w[declared_area_unit unit]]
  composed_of :inter_row_distance, class_name: 'Measure', mapping: [%w[inter_row_distance_value to_d], %w[inter_row_distance_unit unit]]
  composed_of :inter_vine_plant_distance, class_name: 'Measure', mapping: [%w[inter_vine_plant_distance_value to_d], %w[inter_vine_plant_distance_unit unit]]

  belongs_to :cvi_cultivable_zone
  belongs_to :designation_of_origin, class_name: 'RegisteredProtectedDesignationOfOrigin', foreign_key: :designation_of_origin_id
  belongs_to :vine_variety, class_name: 'MasterVineVariety', foreign_key: :vine_variety_id
  belongs_to :activity
  belongs_to :rootstock, class_name: 'MasterVineVariety', foreign_key: :rootstock_id
  has_many :locations, as: :localizable, dependent: :destroy
  has_many :registered_postal_zones, through: :locations
  has_many :cvi_cadastral_plant_cvi_land_parcels, dependent: :destroy
  has_many :cvi_cadastral_plants, through: :cvi_cadastral_plant_cvi_land_parcels
  has_many :rootstocks, through: :cvi_cadastral_plants

  validates :inter_row_distance_value, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 500 }, allow_blank: true
  validates :inter_vine_plant_distance_value, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 200 }, allow_blank: true
  validates :activity_id, presence: true, on: :update
  validates :planting_campaign, presence: true, on: :update
  validates_presence_of :name, :inter_row_distance_value, :inter_vine_plant_distance_value, :vine_variety_id
  validates :shape, shape: true
  before_validation :remove_hole_outside_shell, on: :update, if: -> { shape.hole_outside_shell? }

  def remove_hole_outside_shell
    self.shape = shape.without_hole_outside_shell.to_rgeo
  end

  delegate :name, to: :activity, prefix: true, allow_nil: true

  enumerize :state, in: %i[planted removed_with_authorization], predicates: true

  after_update :update_cvi_cultivable_zone!

  def updated?
    updated_at != created_at
  end

  def regrouped?
    cvi_cadastral_plants.length > 1
  end

  def update_cvi_cultivable_zone!
    cvi_cultivable_zone.update_shape! if shape_changed?
  end
end
