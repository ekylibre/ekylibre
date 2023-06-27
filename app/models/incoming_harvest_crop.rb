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
#  harvest_percentage_repartition :decimal(19, 4)   not null
#  id                          :integer(4)       not null, primary key
#  lock_version                :integer(4)       default(0), not null
#  plant_id                    :integer(4)       not null
#  rows_harvested              :string
#  updated_at                  :datetime         not null
#  updater_id                  :integer(4)
#  wine_incoming_harvest_id    :integer(4)       not null
#

class IncomingHarvestCrop < ApplicationRecord
  belongs_to :incoming_harvest, inverse_of: :crops
  belongs_to :crop, class_name: 'Product'
  belongs_to :harvest_intervention, class_name: 'Intervention'

  delegate :specie_variety_name, to: :crop, prefix: true, allow_nil: true
  delegate :name, to: :crop, prefix: true
  delegate :quantity_unit, to: :incoming_harvest, allow_nil: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :harvest_percentage_repartition, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :crop, :incoming_harvest, presence: true
  # ]VALIDATORS]
  # before link campaign depends on received_at
  refers_to :quantity_unit, class_name: 'Unit'

  scope :of_campaign, lambda { |campaign|
    where(incoming_harvest_id: IncomingHarvest.where(campaign: campaign).pluck(:id))
  }

  before_validation do
    self.harvest_percentage_repartition ||= 100.0
    if harvest_percentage_repartition > 100.0
      self.harvest_percentage_repartition = 100.0
    end
    true
  end

  def net_surface_area_crop
    format('%.4f', crop.net_surface_area.to_f)
  end

  def net_surface_area
    crop.net_surface_area.to_f
  end

  def displayed_harvest_percentage
    harvest_percentage_repartition.round
  end

  def harvest_quantity
    total_quantity_value = incoming_harvest.quantity_value
    harvest_quantity = ((total_quantity_value * harvest_percentage_repartition) / 100).round(2)
    Measure.new(harvest_quantity, incoming_harvest.quantity_unit)
  end
end
