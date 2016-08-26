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
# == Table: inventory_items
#
#  actual_population   :decimal(19, 4)   not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  expected_population :decimal(19, 4)   not null
#  id                  :integer          not null, primary key
#  inventory_id        :integer          not null
#  lock_version        :integer          default(0), not null
#  product_id          :integer          not null
#  product_movement_id :integer
#  updated_at          :datetime         not null
#  updater_id          :integer
#

class InventoryItem < Ekylibre::Record::Base
  belongs_to :inventory, inverse_of: :items
  belongs_to :product
  belongs_to :product_movement, dependent: :destroy
  has_one :container, through: :product

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :actual_population, :expected_population, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :inventory, :product, presence: true
  # ]VALIDATORS]

  delegate :name, :unit_name, :population_counting_unitary?, to: :product
  delegate :reflected?, :achieved_at, to: :inventory

  before_validation do
    self.actual_population = expected_population if population_counting_unitary?
  end

  after_save do
    if reflected?
      movement = build_product_movement unless product_movement
      movement.product = product
      movement.delta = delta
      movement.started_at = achieved_at
      movement.save!
      update_columns(product_movement_id: movement.id)
    elsif product_movement
      ProductMovement.destroy(product_movement)
      update_columns(product_movement_id: nil)
    end
  end

  # Returns the delta population between actual and expectedp populations
  def delta
    actual_population - expected_population
  end
end
