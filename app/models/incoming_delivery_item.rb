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
#  container_id     :integer
#  created_at       :datetime         not null
#  creator_id       :integer
#  delivery_id      :integer          not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  product_id       :integer          not null
#  purchase_item_id :integer
#  quantity         :decimal(19, 4)   default(1.0), not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class IncomingDeliveryItem < Ekylibre::Record::Base
  # attr_accessible :delivery_id, :product_id, :product_attributes, :quantity, :container_id, :product_nature_variant_id
  attr_readonly :purchase_item_id, :product_id
  attr_accessor :product_nature_variant_id
  belongs_to :delivery, :class_name => "IncomingDelivery", :inverse_of => :items
  # belongs_to :price, :class_name => "CatalogPrice"
  belongs_to :container, :class_name => "Product"
  belongs_to :product
  belongs_to :purchase_item, :class_name => "PurchaseItem"
  # belongs_to :move, :class_name => "ProductMove"
  # enumerize :unit, :in => Nomen::Units.all
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_presence_of :delivery, :product, :quantity
  #]VALIDATORS]
  validates_presence_of :product#, :unit

  accepts_nested_attributes_for :product
  acts_as_stockable :origin => :delivery
  delegate :variant, :name, :to => :product, :prefix => true
  #delegate :weight, :name, :to => :product, :prefix => true
  #sums :delivery, :items, "item.product_weight.to_f * item.quantity" => :weight

  before_validation do
    if self.purchase_item
      self.product_id  = self.purchase_item.product_id
    end
  end

  # validate(:on => :create) do
  #   if self.product
  #     maximum = self.undelivered_quantity
  #     errors.add(:quantity, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.unit.name, :product => self.product_name) if (self.quantity > maximum)
  #   end
  # end

  # validate(:on => :update) do
  #   old_self = self.class.find(self.id)
  #   maximum = self.undelivered_quantity + old_self.quantity
  #   errors.add(:quantity, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.unit.name, :product => self.product_name) if (self.quantity > maximum)
  # end

end
