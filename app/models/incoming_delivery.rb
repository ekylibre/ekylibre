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
# == Table: incoming_deliveries
#
#  amount            :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes :decimal(16, 2)   default(0.0), not null
#  comment           :text             
#  company_id        :integer          not null
#  contact_id        :integer          
#  created_at        :datetime         not null
#  creator_id        :integer          
#  currency_id       :integer          
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          
#  moved_on          :date             
#  number            :string(255)      
#  planned_on        :date             
#  purchase_order_id :integer          
#  reference_number  :string(255)      
#  updated_at        :datetime         not null
#  updater_id        :integer          
#  weight            :decimal(16, 4)   
#


class IncomingDelivery < ActiveRecord::Base
  attr_readonly :company_id, :number
  belongs_to :contact
  belongs_to :company
  belongs_to :currency
  belongs_to :mode, :class_name=>IncomingDeliveryMode.name
  belongs_to :purchase_order
  has_many :lines, :class_name=>IncomingDeliveryLine.name, :foreign_key=>:delivery_id, :dependent=>:destroy
  has_many :stock_moves, :as=>:origin

  validates_presence_of :planned_on

  def prepare
    self.company_id = self.purchase_order.company_id if self.purchase_order
    if self.number.blank?
      last = self.company.incoming_deliveries.find(:first, :order=>"number desc")
      self.number = last ? last.number.succ! : '00000001'
    end
    self.amount = self.amount_with_taxes = self.weight = 0.0
    for line in self.lines
      self.amount += line.amount
      self.amount_with_taxes += line.amount_with_taxes
      self.weight += (line.product.weight||0)*line.quantity
    end
    return true
  end

  def clean_on_create
    specific_numeration = self.company.preference("management.incoming_deliveries.numeration").value
    self.number = specific_numeration.next_value unless specific_numeration.nil?
  end
  

  # Only used for Kame usage
  def quantity
    nil
  end

end
