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
# == Table: stock_transfers
#
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  moved_on            :date             
#  nature              :string(8)        not null
#  planned_on          :date             not null
#  product_id          :integer          not null
#  quantity            :decimal(16, 4)   not null
#  second_warehouse_id :integer          
#  tracking_id         :integer          
#  unit_id             :integer          
#  updated_at          :datetime         not null
#  updater_id          :integer          
#  warehouse_id        :integer          not null
#


class StockTransfer < CompanyRecord
  after_save :move_stocks
  attr_readonly :company_id, :nature
  before_update {|r| r.stock_moves.clear}
  belongs_to :company
  belongs_to :product
  belongs_to :warehouse
  belongs_to :second_warehouse, :class_name=>Warehouse.to_s
  belongs_to :unit
  has_many :stock_moves, :as=>:origin, :dependent=>:destroy
  validates_presence_of :unit_id
  validates_presence_of :second_warehouse_id, :if=>Proc.new{|x| x.transfer?}

  before_validation do
    self.unit_id = self.product.unit_id if self.product
    self.moved_on =  Date.today if self.planned_on <= Date.today
    self.second_warehouse_id = nil unless self.transfer? # if self.nature == "waste"
  end

  validate do
    if !self.second_warehouse.nil?
      errors.add_to_base(:warehouse_can_not_receive_product, :warehouse=>self.second_warehouse.name, :product=>self.product.name, :contained_product=>self.second_warehouse.product.name) unless self.second_warehouse.can_receive(self.product_id)
    end
    unless self.warehouse.can_receive(self.product_id)
      errors.add_to_base(:warehouse_can_not_transfer_product, :warehouse=>self.warehouse.name, :product=>self.product.name, :contained_product=>self.warehouse.product.name) if self.nature=="transfer"
      errors.add_to_base(:warehouse_can_not_waste_product, :warehouse=>self.warehouse.name, :product=>self.product.name, :contained_product=>self.warehouse.product.name) if self.nature=="waste"
    end
    errors.add_to_base(:warehouses_can_not_be_identical) if self.warehouse_id == self.second_warehouse_id 
  end

  transfer do |t|
    t.move(:quantity=>-self.quantity, :warehouse=>self.warehouse)
    t.move(:quantity=>self.quantity, :warehouse=>self.second_warehouse) if self.transfer?
  end

  
  def move_stocks
    self.product.reserve_outgoing_stock(:origin=>self, :planned_on=>self.planned_on, :moved_on=>self.moved_on)
    self.product.move_outgoing_stock(:origin=>self, :planned_on=>self.planned_on, :moved_on=>self.moved_on) if self.moved_on
    if self.transfer?
      self.product.reserve_incoming_stock(:origin=>self, :warehouse_id=>self.second_warehouse_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on)
      self.product.move_incoming_stock(:origin=>self, :warehouse_id=>self.second_warehouse_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on)  if self.moved_on
    end
  end
  
  def self.natures
    [:transfer, :waste].collect{|x| [tc('natures.'+x.to_s), x] }
  end


  def text_nature
    tc('natures.'+self.nature.to_s)
  end

  def transfer?
    self.nature.to_s == "transfer"
  end

  
  def execute_transfer
    self.moved_on = Date.today
    self.save
    StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :warehouse_id=>self.warehouse_id, :product_id=>self.product_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>false, :input=>false, :origin_type=>StockTransfer.to_s, :origin_id=>self.id, :generated=>true)
    StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :warehouse_id=>self.second_warehouse_id, :product_id=>self.product_id,:planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>false, :input=>true,:origin_type=>StockTransfer.to_s, :origin_id=>self.id, :generated=>true)  if self.nature == "transfer"
  end
  
end
