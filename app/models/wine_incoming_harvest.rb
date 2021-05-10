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
# == Table: wine_incoming_harvests
#
#  additional_informations :jsonb            default("{}")
#  analysis_id             :integer
#  campaign_id             :integer          not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  description             :text
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  number                  :string
#  quantity_unit           :string           not null
#  quantity_value          :decimal(19, 4)   not null
#  received_at             :datetime         not null
#  ticket_number           :string
#  updated_at              :datetime         not null
#  updater_id              :integer
#

class WineIncomingHarvest < ApplicationRecord
  include Attachable
  belongs_to :analysis, class_name: 'Analysis'
  belongs_to :campaign, class_name: 'Campaign'
  has_many :inputs, class_name: 'WineIncomingHarvestInput', dependent: :destroy
  has_many :plants, class_name: 'WineIncomingHarvestPlant', dependent: :destroy
  has_many :storages, class_name: 'WineIncomingHarvestStorage', dependent: :destroy
  has_many :presses, class_name: 'WineIncomingHarvestPress', dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :ticket_number, length: { maximum: 500 }, allow_blank: true
  validates :campaign, :quantity_unit, presence: true
  validates :quantity_value, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :received_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  # ]VALIDATORS]
  composed_of :quantity, class_name: 'Measure', mapping: [%w[quantity_value to_d], %w[quantity_unit unit]]
  acts_as_numbered :number, readonly: false

  refers_to :quantity_unit, class_name: 'Unit'

  accepts_nested_attributes_for :plants
  accepts_nested_attributes_for :storages
  accepts_nested_attributes_for :presses

  serialize :additional_informations, HashSerializer
  store_accessor :additional_informations, :sedimentation_duration, :vehicle_trailer, :harvest_transportation_duration, :last_load, :harvest_nature, :harvest_dock, :harvest_description

  # before link campaign depends on received_at
  before_validation do
    self.campaign = Campaign.on(received_at)
  end

  after_destroy do
    analysis.reload
    analysis.destroy!
  end

  def human_plants_names
    self.plants.map(&:plant).map(&:name).to_sentence
  end

  def human_storages_names
    self.storages.map(&:storage).map(&:name).to_sentence
  end

  def net_harvest_areas_sum
    format('%.4f', self.plants.sum(&:net_harvest_area))
  end

  def human_species_variesties_names
    self.plants.map(&:plant).map(&:specie_variety_name).to_sentence
  end

  def tavp
    analysis&.items&.find_by(indicator_name: :estimated_harvest_alcoholic_volumetric_concentration)&.absolute_measure_value_value&.to_f
  end

  def wine_incoming_harvest_reporting(_options = {})
    report = HashWithIndifferentAccess.new

    report[:wine_harvest_number] = number
    report[:wine_harvest_ticket_number] = ticket_number
    report[:wine_harvest_received_at] = received_at.strftime("%d/%m/%y %H:%M")
    report[:wine_harvest_plants_name] = human_plants_names
    report[:wine_net_harvest_area] = net_harvest_areas_sum
    report[:quantity_value] = quantity_value.to_f
    report[:quantity_unit] = quantity_unit.tl
    report[:wine_harvest_storages_name] = human_storages_names
    report[:wine_harvest_tavp] = tavp
    report[:wine_harvest_species_name] = human_species_variesties_names
    report
  end
end
