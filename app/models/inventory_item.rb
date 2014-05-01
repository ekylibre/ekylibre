# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: inventory_items
#
#  created_at              :datetime         not null
#  creator_id              :integer
#  expected_population     :decimal(19, 4)   not null
#  expected_shape          :spatial({:srid=>
#  id                      :integer          not null, primary key
#  inventory_id            :integer          not null
#  lock_version            :integer          default(0), not null
#  population              :decimal(19, 4)   not null
#  product_id              :integer          not null
#  product_reading_task_id :integer
#  shape                   :spatial({:srid=>
#  updated_at              :datetime         not null
#  updater_id              :integer
#


class InventoryItem < Ekylibre::Record::Base
  belongs_to :inventory, inverse_of: :items
  belongs_to :product
  has_one :container, through: :product

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :expected_population, :population, allow_nil: true
  validates_presence_of :expected_population, :inventory, :population, :product
  #]VALIDATORS]

  delegate :name, :unit_name, :population_counting_unitary?, to: :product

  before_validation do
    if self.population_counting_unitary?
      self.actual_population = self.expected_population
    end
  end

  # acts_as_stockable :quantity => "self.quantity - self.theoric_quantity", :origin => :inventory

  # def stock_id=(id)
  #   if s = ProductStock.find_by_id(id)
  #     self.product_id  = s.product_id
  #     self.building_id = s.building_id
  #     self.theoric_quantity = s.quantity||0
  #     self.unit     = s.unit
  #   end
  # end

  # def tracking_name
  #   return self.tracking ? self.tracking.name : ""
  # end

end
