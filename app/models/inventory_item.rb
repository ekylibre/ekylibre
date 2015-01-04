# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  actual_shape        :spatial({:srid=>
#  created_at          :datetime         not null
#  creator_id          :integer
#  expected_population :decimal(19, 4)   not null
#  expected_shape      :spatial({:srid=>
#  id                  :integer          not null, primary key
#  inventory_id        :integer          not null
#  lock_version        :integer          default(0), not null
#  product_id          :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class InventoryItem < Ekylibre::Record::Base
  belongs_to :inventory, inverse_of: :items
  belongs_to :product
  has_one :container, through: :product

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :actual_population, :expected_population, allow_nil: true
  validates_presence_of :actual_population, :expected_population, :inventory, :product
  #]VALIDATORS]

  delegate :name, :unit_name, :population_counting_unitary?, to: :product

  before_validation do
    if self.population_counting_unitary?
      self.actual_population = self.expected_population
    end
  end

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
