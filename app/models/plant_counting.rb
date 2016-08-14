# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: plant_countings
#
#  average_value                :decimal(19, 4)
#  comment                      :text
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  id                           :integer          not null, primary key
#  lock_version                 :integer          default(0), not null
#  plant_density_abacus_id      :integer          not null
#  plant_density_abacus_item_id :integer          not null
#  plant_id                     :integer          not null
#  read_at                      :datetime
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#

class PlantCounting < Ekylibre::Record::Base
  belongs_to :plant
  belongs_to :plant_density_abacus
  belongs_to :plant_density_abacus_item
  has_many :items, class_name: 'PlantCountingItem', dependent: :delete_all, inverse_of: :plant_counting

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :average_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :comment, length: { maximum: 500_000 }, allow_blank: true
  validates :read_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :plant, :plant_density_abacus, :plant_density_abacus_item, presence: true
  # ]VALIDATORS]

  accepts_nested_attributes_for :items

  before_validation do
    if plant_density_abacus_item
      self.plant_density_abacus = plant_density_abacus_item.plant_density_abacus
    end
  end
end
