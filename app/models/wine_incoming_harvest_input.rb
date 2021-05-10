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
# == Table: wine_incoming_harvest_inputs
#
#  created_at               :datetime         not null
#  creator_id               :integer
#  id                       :integer          not null, primary key
#  input_id                 :integer          not null
#  lock_version             :integer          default(0), not null
#  quantity_unit            :string           not null
#  quantity_value           :decimal(19, 4)   not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  wine_incoming_harvest_id :integer          not null
#

class WineIncomingHarvestInput < ApplicationRecord
  belongs_to :wine_incoming_harvest
  belongs_to :input, class_name: 'Product'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :quantity_unit, presence: true, length: { maximum: 500 }
  validates :quantity_value, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :input, :wine_incoming_harvest, presence: true
  # ]VALIDATORS]
  # before link campaign depends on received_at
  composed_of :quantity, class_name: 'Measure', mapping: [%w[quantity_value to_d], %w[quantity_unit unit]]
end
