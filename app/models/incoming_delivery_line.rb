# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: incoming_delivery_lines
#
#  amount           :decimal(16, 2)   default(0.0), not null
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  delivery_id      :integer          not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  pretax_amount    :decimal(16, 2)   default(0.0), not null
#  price_id         :integer          not null
#  product_id       :integer          not null
#  purchase_line_id :integer          not null
#  quantity         :decimal(16, 4)   default(1.0), not null
#  stock_move_id    :integer          
#  tracking_id      :integer          
#  unit_id          :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  warehouse_id     :integer          
#  weight           :decimal(16, 4)   
#


class IncomingDeliveryLine < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :weight, :allow_nil => true
  #]VALIDATORS]
  acts_as_stockable :origin=>:delivery
  attr_readonly :purchase_line_id, :product_id, :price_id, :unit_id
  belongs_to :delivery, :class_name=>"IncomingDelivery"
  belongs_to :price
  belongs_to :product
  belongs_to :purchase_line, :class_name=>"PurchaseLine"
  belongs_to :stock_move
  belongs_to :tracking
  belongs_to :unit
  belongs_to :warehouse
  validates_presence_of :product_id, :unit_id

  sums :delivery, :lines, :pretax_amount, :amount, "(line.product.weight||0)*line.quantity"=>:weight

  before_validation do
    self.company_id = self.delivery.company_id if self.delivery
    if self.purchase_line
      self.product_id  = self.purchase_line.product_id
      self.price_id    = self.purchase_line.price.id
      self.unit_id     = self.purchase_line.unit_id
      self.warehouse_id = self.purchase_line.warehouse_id
    end
    self.pretax_amount = self.purchase_line.price.pretax_amount*self.quantity
    self.amount = self.purchase_line.price.amount*self.quantity
  end
  
  validate(:on=>:create) do
    if self.product
      maximum = self.undelivered_quantity
      errors.add_to_base(:greater_than_undelivered_quantity, :maximum=>maximum, :unit=>self.product.unit.name, :product=>self.product_name) if (self.quantity > maximum)
    end
  end

  validate(:on=>:update) do
    old_self = self.class.find(self.id)
    maximum = self.undelivered_quantity + old_self.quantity
    errors.add_to_base(:greater_than_undelivered_quantity, :maximum=>maximum, :unit=>self.product.unit.name, :product=>self.product_name) if (self.quantity > maximum)
  end

  def undelivered_quantity
    self.purchase_line.undelivered_quantity
  end

  def product_name
    self.product.name
  end

end
