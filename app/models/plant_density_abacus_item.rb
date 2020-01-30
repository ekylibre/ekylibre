# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: plant_density_abacus_items
#
#  created_at              :datetime         not null
#  creator_id              :integer
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  plant_density_abacus_id :integer          not null
#  plants_count            :integer
#  seeding_density_value   :decimal(19, 4)   not null
#  updated_at              :datetime         not null
#  updater_id              :integer
#

class PlantDensityAbacusItem < Ekylibre::Record::Base
  belongs_to :plant_density_abacus, inverse_of: :items
  has_many :plant_countings, dependent: :restrict_with_exception

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :seeding_density_value, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :plant_density_abacus, presence: true
  # ]VALIDATORS]

  scope :of_abacus, ->(id) { where(plant_density_abacus_id: id) }

  protect on: :destroy do
    plant_countings.any?
  end

  def to_s
    "#{plants_count} - #{seeding_density_value.in(plant_density_abacus.seeding_density_unit).l}"
  end
end
