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
# == Table: plant_density_abaci
#
#  activity_id            :integer          not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  germination_percentage :decimal(19, 4)
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string           not null
#  sampling_length_unit   :string           not null
#  seeding_density_unit   :string           not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

class PlantDensityAbacus < Ekylibre::Record::Base
  belongs_to :activity, inverse_of: :plant_density_abaci
  has_many :items, class_name: 'PlantDensityAbacusItem', dependent: :delete_all, inverse_of: :plant_density_abacus
  has_many :plant_countings

  refers_to :seeding_density_unit, class_name: 'Unit'
  refers_to :sampling_length_unit, class_name: 'Unit'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :germination_percentage, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :activity, :sampling_length_unit, :seeding_density_unit, presence: true
  # ]VALIDATORS]
  validates :name, uniqueness: true

  delegate :cultivation_variety, to: :activity

  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true

  protect on: :destroy do
    plant_countings.any?
  end

  def variety_name
    activity ? cultivation_variety : nil
  end
end
