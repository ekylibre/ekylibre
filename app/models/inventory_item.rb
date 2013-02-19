# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  inventory_id     :integer          not null
#  lock_version     :integer          default(0), not null
#  move_id          :integer
#  product_id       :integer          not null
#  quantity         :decimal(19, 4)   not null
#  theoric_quantity :decimal(19, 4)   not null
#  tracking_id      :integer
#  unit_id          :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#  warehouse_id     :integer          not null
#


class InventoryItem < Ekylibre::Record::Base
  attr_accessible :product_id, :quantity, :unit_id, :warehouse_id
  belongs_to :inventory, :inverse_of => :items
  belongs_to :product
  belongs_to :move, :class_name => "ProductMove"
  belongs_to :unit

  #[VALIDATORS[ Do not edit these items directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :theoric_quantity, :allow_nil => true
  validates_presence_of :inventory, :product, :quantity, :theoric_quantity
  #]VALIDATORS]

  acts_as_stockable :quantity => "self.quantity - self.theoric_quantity", :origin => :inventory

  # def stock_id=(id)
  #   if s = ProductStock.find_by_id(id)
  #     self.product_id  = s.product_id
  #     self.warehouse_id = s.warehouse_id
  #     self.theoric_quantity = s.quantity||0
  #     self.unit_id     = s.unit_id
  #   end
  # end

  # def tracking_name
  #   return self.tracking ? self.tracking.name : ""
  # end

end
