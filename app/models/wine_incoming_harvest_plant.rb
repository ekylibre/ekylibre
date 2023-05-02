# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: wine_incoming_harvest_plants
#
#  created_at                  :datetime         not null
#  creator_id                  :integer(4)
#  harvest_percentage_received :decimal(19, 4)   not null
#  id                          :integer(4)       not null, primary key
#  lock_version                :integer(4)       default(0), not null
#  plant_id                    :integer(4)       not null
#  rows_harvested              :string
#  updated_at                  :datetime         not null
#  updater_id                  :integer(4)
#  wine_incoming_harvest_id    :integer(4)       not null
#

class WineIncomingHarvestPlant < ApplicationRecord
  belongs_to :wine_incoming_harvest
  belongs_to :plant, class_name: 'Plant'

  delegate :specie_variety_name, to: :plant, prefix: true, allow_nil: true
  delegate :name, to: :plant, prefix: true
  delegate :quantity_unit, to: :wine_incoming_harvest, allow_nil: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :harvest_percentage_received, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :rows_harvested, length: { maximum: 500 }, allow_blank: true
  validates :plant, :wine_incoming_harvest, presence: true
  # ]VALIDATORS]
  # before link campaign depends on received_at
  refers_to :quantity_unit, class_name: 'Unit'

  def net_surface_area_plant
    format('%.4f', plant.net_surface_area.to_f)
  end

  def net_harvest_area
    (harvest_percentage_received / 100) * plant.net_surface_area.to_f
  end

  def displayed_harvest_percentage
    harvest_percentage_received.round
  end

  def displayed_net_harvest_area
    format('%.4f', net_harvest_area)
  end

  def harvest_quantity
    total_net_harvest_area = WineIncomingHarvestPlant.where(wine_incoming_harvest_id: wine_incoming_harvest_id).map(&:net_harvest_area).sum
    percentage_net_surface_area_received = (net_harvest_area / total_net_harvest_area) * 100
    total_quantity_value = wine_incoming_harvest.quantity_value
    harvest_quantity = ((total_quantity_value * percentage_net_surface_area_received) / 100).round(2)
  end
end
