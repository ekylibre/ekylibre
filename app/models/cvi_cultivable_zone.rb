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
# == Table: cvi_cultivable_zones
#
#  calculated_area_unit  :string
#  calculated_area_value :decimal(19, 4)
#  created_at            :datetime         not null
#  creator_id            :integer
#  cvi_statement_id      :integer
#  declared_area_unit    :string
#  declared_area_value   :decimal(19, 4)
#  id                    :integer          not null, primary key
#  land_parcels_status   :string           default("not_started")
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  shape                 :polygon          not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#
class CviCultivableZone < CviShapedRecord
  composed_of :calculated_area, class_name: 'Measure', mapping: [%w[calculated_area_value to_d], %w[calculated_area_unit unit]]
  composed_of :declared_area, class_name: 'Measure', mapping: [%w[declared_area_value to_d], %w[declared_area_unit unit]]

  belongs_to :cvi_statement
  has_many :cvi_cadastral_plants, dependent: :nullify
  has_many :cvi_land_parcels, dependent: :destroy
  has_many :locations, as: :localizable, dependent: :destroy
  has_many :registered_postal_zone, through: :locations
  validates_presence_of :name

  enumerize :land_parcels_status, in: %i[not_started started not_created created completed], predicates: true

  after_save :set_calculated_area, on: %i[create update], if: :shape_changed?

  def has_cvi_land_parcels?
    cvi_land_parcels.any?
  end

  def land_parcels_valid?
    cvi_land_parcels.pluck(:planting_campaign).none?(&:nil?)
  end

  def update_shape!
    update!(shape: CviCultivableZoneService::ShapeCalculator.calculate(self, shape.to_rgeo))
  end

  def complete!
    update!(land_parcels_status: :completed)
  end
end
