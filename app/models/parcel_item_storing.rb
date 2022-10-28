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
# == Table: parcel_item_storings
#
#  conditionning          :decimal(19, 4)
#  conditionning_quantity :decimal(19, 4)
#  created_at             :datetime         not null
#  creator_id             :integer
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  parcel_item_id         :integer          not null
#  product_id             :integer
#  quantity               :decimal(19, 4)
#  storage_id             :integer          not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#
class ParcelItemStoring < ApplicationRecord
  belongs_to :parcel_item, inverse_of: :storings
  belongs_to :storage, class_name: 'Product'
  belongs_to :product, class_name: 'Product', foreign_key: :product_id
  belongs_to :conditioning_unit, class_name: 'Unit'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :conditioning_quantity, presence: true, numericality: { greater_than: -10_000_000_000, less_than: 10_000_000_000 }
  validates :quantity, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :conditioning_unit, :parcel_item, :storage, presence: true
  # ]VALIDATORS]
  validates :quantity, presence: true
  validates :conditioning_unit, conditioning: true

  delegate :variant, to: :parcel_item
  delegate :dimension, :of_dimension?, to: :unit

  alias_attribute :unit, :conditioning_unit

  before_validation do
    self.quantity ||= UnitComputation.convert_into_variant_population(parcel_item.variant, conditioning_quantity, conditioning_unit)
    parcel_item.conditioning_quantity ||= conditioning_quantity
    parcel_item.conditioning_unit ||= conditioning_unit
  end

  after_create do
    population = parcel_item.population
    population += quantity
    parcel_item.update_attributes(population: population)
  end

  after_update do
    population = parcel_item.population
    population -= quantity_before_last_save
    population += quantity
    parcel_item.update_attributes(population: population)
  end

  after_destroy do
    population = parcel_item.population
    population -= quantity_was
    parcel_item.update_attributes(population: population)
  end

  def reception
    Reception.find(parcel_item.parcel_id)
  end

  delegate :number, to: :reception, prefix: true

  # FIXME: Invalid method name for human data. Prefer reception_nature_label or
  #        human_reception_nature
  def reception_nature
    reception.nature.tl
  end

  delegate :given_at, to: :reception, prefix: true
end
