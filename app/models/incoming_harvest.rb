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
# == Table: wine_incoming_harvests
#
#  additional_informations :jsonb            default("{}")
#  analysis_id             :integer(4)
#  campaign_id             :integer(4)       not null
#  created_at              :datetime         not null
#  creator_id              :integer(4)
#  description             :text
#  id                      :integer(4)       not null, primary key
#  lock_version            :integer(4)       default(0), not null
#  number                  :string
#  quantity_unit           :string           not null
#  quantity_value          :decimal(19, 4)   not null
#  received_at             :datetime         not null
#  ticket_number           :string
#  updated_at              :datetime         not null
#  updater_id              :integer(4)
#

class IncomingHarvest < ApplicationRecord
  include Attachable
  belongs_to :analysis, class_name: 'Analysis'
  belongs_to :driver, class_name: 'Product'
  belongs_to :trailer, class_name: 'Product'
  belongs_to :tractor, class_name: 'Product'
  belongs_to :intervention
  belongs_to :campaign, class_name: 'Campaign'
  has_many :crops, class_name: 'IncomingHarvestCrop', dependent: :destroy, inverse_of: :incoming_harvest
  has_many :storages, class_name: 'IncomingHarvestStorage', dependent: :destroy, inverse_of: :incoming_harvest
  has_many :product_crops, through: :crops, source: :crop
  has_many :product_storages, through: :storages, source: :storage

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

  accepts_nested_attributes_for :crops
  accepts_nested_attributes_for :storages

  serialize :additional_informations, HashSerializer
  store_accessor :additional_informations, :vehicle_trailer, :harvest_transportation_duration, :harvest_nature, :harvest_dock, :harvest_description

  scope :between, lambda { |started_at, stopped_at|
    where(received_at: started_at..stopped_at)
  }

  # before link campaign depends on received_at
  before_validation do
    if received_at && Campaign.on(received_at).present?
      self.campaign = Campaign.on(received_at)
    end
  end

  after_destroy do
    if analysis
      analysis.reload
      analysis.destroy!
    end
  end

  after_save do
    IncomingHarvestIndicator.refresh
  end

  def human_crops_names
    self.product_crops.pluck(:name).to_sentence
  end

  def human_storages_names
    self.product_storages.pluck(:name).to_sentence
  end

  def net_harvest_areas_sum
    format('%.4f', self.crops.map(&:net_surface_area).sum.round(2))
  end

  def human_species_variesties_names
    self.product_crops.map(&:specie_variety_name).to_sentence
  end

  # Returns status of affair if invoiced else "stop"
  def status
    if crops.any? && crops.count == crops.where.not(harvest_intervention_id: nil).count
      :go
    elsif crops.any? && crops.count != crops.where.not(harvest_intervention_id: nil).count
      :caution
    else
      :stop
    end
  end

end
