# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
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
# == Table: sales_invoice_lines
#
#  amount            :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes :decimal(16, 2)   default(0.0), not null
#  annotation        :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  entity_id         :integer          
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  order_line_id     :integer          
#  origin_id         :integer          
#  position          :integer          
#  price_id          :integer          not null
#  product_id        :integer          not null
#  quantity          :decimal(16, 4)   default(1.0), not null
#  sales_invoice_id  :integer          
#  tracking_id       :integer          
#  unit_id           :integer          
#  updated_at        :datetime         not null
#  updater_id        :integer          
#  warehouse_id      :integer          
#


class SalesInvoiceLine < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  belongs_to :entity
  belongs_to :sales_invoice
  belongs_to :order_line, :class_name=>SalesOrderLine.name
  belongs_to :origin, :class_name=>SalesInvoiceLine.name
  belongs_to :price
  belongs_to :product
  has_many :credit_lines, :class_name=>SalesInvoiceLine.name, :foreign_key=>:origin_id

  sums :sales_invoice, :lines, :amount, :amount_with_taxes
  validates_presence_of :order_line_id

  attr_readonly :company_id, :sales_invoice_id, :order_line_id, :quantity, :amount, :amount_with_taxes, :annotation, :price_id, :product_id
  
  def prepare
    self.company_id = self.sales_invoice.company_id if self.sales_invoice
    self.product = self.order_line.product
    self.price_id = self.order_line.price.id
    self.annotation = self.order_line.annotation
    unless self.origin_id.nil?
      self.amount = self.quantity * self.price.amount
      self.amount_with_taxes = self.quantity * self.price.amount_with_taxes
    end
  end
  
  def check
    unless self.origin_id.nil?
      if self.origin.quantity > 0
        errors.add(:quantity) if -self.quantity > self.origin.quantity
      else
        errors.add(:quantity) if -self.quantity < self.origin.quantity
      end
    end
  end

  def product_name
    self.product ? self.product.name : tc(:no_product) 
  end
  
  def label
    self.order_line ? self.order_line.label : product_name
  end
  

  def taxes
    self.amount_with_taxes - self.amount
  end  
  
  def designation
    d  = self.label
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d
  end

  
  def credited_quantity
    self.credit_lines.sum(:quantity)*-1
  end

  def uncredited_quantity
    self.quantity - self.credited_quantity
  end

end
