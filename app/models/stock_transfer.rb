# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
#  comment            :text             
#  company_id         :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer          
#  id                 :integer          not null, primary key
#  location_id        :integer          not null
#  lock_version       :integer          default(0), not null
#  moved_on           :date             
#  nature             :string(8)        not null
#  planned_on         :date             not null
#  product_id         :integer          not null
#  quantity           :decimal(16, 4)   not null
#  second_location_id :integer          
#  tracking_id        :integer          
#  unit_id            :integer          
#  updated_at         :datetime         not null
#  updater_id         :integer          
#

class StockTransfer < ActiveRecord::Base
  after_save :move_stocks
  attr_readonly :company_id, :nature
  before_update {|r| r.stock_moves.clear}
  belongs_to :company
  belongs_to :product
  belongs_to :location
  belongs_to :second_location, :class_name=>Location.to_s
  belongs_to :unit
  has_many :stock_moves, :as=>:origin, :dependent=>:destroy
  validates_presence_of :unit_id
  validates_presence_of :second_location_id, :if=>Proc.new{|x| x.transfer?}

  def prepare
    self.unit_id = self.product.unit_id if self.product
    self.moved_on =  Date.today if self.planned_on <= Date.today
    self.second_location_id = nil unless self.transfer? # if self.nature == "waste"
  end

  def check
    if !self.second_location.nil?
      errors.add_to_base(:location_can_not_receive_product, :location=>self.second_location.name, :product=>self.product.name, :contained_product=>self.second_location.product.name) unless self.second_location.can_receive(self.product_id)
    end
    unless self.location.can_receive(self.product_id)
      errors.add_to_base(:location_can_not_transfer_product, :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name) if self.nature=="transfer"
      errors.add_to_base(:location_can_not_waste_product, :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name) if self.nature=="waste"
    end
    errors.add_to_base(:locations_can_not_be_identical) if self.location_id == self.second_location_id 
      
  end
  
  def move_stocks
    self.product.reserve_outgoing_stock(:origin=>self, :planned_on=>self.planned_on, :moved_on=>self.moved_on)
    self.product.move_outgoing_stock(:origin=>self, :planned_on=>self.planned_on, :moved_on=>self.moved_on) if self.moved_on
    if self.transfer?
      self.product.reserve_incoming_stock(:origin=>self, :location_id=>self.second_location_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on)
      self.product.move_incoming_stock(:origin=>self, :location_id=>self.second_location_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on)  if self.moved_on
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
    StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>false, :input=>false, :origin_type=>StockTransfer.to_s, :origin_id=>self.id, :generated=>true)
    StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :location_id=>self.second_location_id, :product_id=>self.product_id,:planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>false, :input=>true,:origin_type=>StockTransfer.to_s, :origin_id=>self.id, :generated=>true)  if self.nature == "transfer"
  end
  
end
