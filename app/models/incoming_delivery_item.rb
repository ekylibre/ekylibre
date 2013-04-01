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
# == Table: incoming_delivery_items
#
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  delivery_id      :integer          not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  move_id          :integer
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  price_id         :integer          not null
#  product_id       :integer          not null
#  purchase_item_id :integer          not null
#  quantity         :decimal(19, 4)   default(1.0), not null
#  tracking_id      :integer
#  unit_id          :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  warehouse_id     :integer
#  weight           :decimal(19, 4)
#


class IncomingDeliveryItem < Ekylibre::Record::Base
  attr_accessible :delivery_id, :price_id, :product_id, :warehouse_id
  attr_readonly :purchase_item_id, :product_id, :price_id, :unit_id
  belongs_to :delivery, :class_name => "IncomingDelivery"
  belongs_to :price, :class_name => "ProductPrice"
  belongs_to :product
  belongs_to :purchase_item, :class_name => "PurchaseItem"
  belongs_to :move, :class_name => "ProductMove"
  belongs_to :unit
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :weight, :allow_nil => true
  validates_presence_of :amount, :delivery, :pretax_amount, :price, :product, :purchase_item, :quantity, :unit
  #]VALIDATORS]
  validates_presence_of :product, :unit

  acts_as_stockable :origin => :delivery
  sums :delivery, :items, :pretax_amount, :amount, "(item.product.weight||0)*item.quantity" => :weight

  before_validation do
    if self.purchase_item
      self.product_id  = self.purchase_item.product_id
      self.price_id    = self.purchase_item.price.id
      self.unit_id     = self.purchase_item.unit_id
      self.warehouse_id = self.purchase_item.warehouse_id
    end
    self.pretax_amount = self.purchase_item.price.pretax_amount*self.quantity
    self.amount = self.purchase_item.price.amount*self.quantity
  end

  validate(:on => :create) do
    if self.product
      maximum = self.undelivered_quantity
      errors.add(:quantity, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.unit.name, :product => self.product_name) if (self.quantity > maximum)
    end
  end

  validate(:on => :update) do
    old_self = self.class.find(self.id)
    maximum = self.undelivered_quantity + old_self.quantity
    errors.add(:quantity, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.unit.name, :product => self.product_name) if (self.quantity > maximum)
  end

  def undelivered_quantity
    self.purchase_item.undelivered_quantity
  end

  def product_name
    self.product.name
  end

end
