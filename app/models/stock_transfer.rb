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
# == Table: stock_transfers
#
#  comment              :text             
#  created_at           :datetime         not null
#  creator_id           :integer          
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  moved_on             :date             
#  nature               :string(8)        not null
#  number               :string(64)       not null
#  planned_on           :date             not null
#  product_id           :integer          not null
#  quantity             :decimal(19, 4)   not null
#  second_stock_move_id :integer          
#  second_warehouse_id  :integer          
#  stock_move_id        :integer          
#  tracking_id          :integer          
#  unit_id              :integer          
#  updated_at           :datetime         not null
#  updater_id           :integer          
#  warehouse_id         :integer          not null
#


class StockTransfer < CompanyRecord
  attr_accessible :comment, :nature, :planned_on, :product_id, :quantity, :second_warehouse_id, :tracking_id, :unit_id, :warehouse_id
  attr_readonly :nature
  enumerize :nature, :in => [:waste, :transfer, :gain], :default => :transfer, :predicates => true
  belongs_to :product, :class_name => "ProductNature"
  belongs_to :second_stock_move, :class_name => "StockMove"
  belongs_to :second_warehouse, :class_name => "Warehouse"
  belongs_to :stock_move
  belongs_to :tracking
  belongs_to :unit
  belongs_to :warehouse
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :nature, :allow_nil => true, :maximum => 8
  validates_length_of :number, :allow_nil => true, :maximum => 64
  validates_presence_of :nature, :number, :planned_on, :product, :quantity, :warehouse
  #]VALIDATORS]
  validates_presence_of :unit
  validates_presence_of :second_warehouse, :if => :transfer?
  validates_numericality_of :quantity, :greater_than => 0.0
  validates_inclusion_of :nature, :in => self.nature.values

  scope :unconfirmeds, where(:moved_on => nil)

  acts_as_numbered
  acts_as_stockable :quantity => '-self.quantity'
  acts_as_stockable :second_stock_move, :warehouse => :second_warehouse, :if => :transfer?


  before_validation do
    self.unit_id = self.product.unit_id if self.product
    if self.planned_on
      self.moved_on = Date.today if self.planned_on <= Date.today
    end
    self.second_warehouse_id = nil unless self.transfer? # if self.nature == "waste"
  end

  validate do
    if self.tracking
      errors.add(:tracking_id, :invalid) if self.tracking.product_id != self.product_id
    end
    if self.unit
      errors.add(:unit_id, :invalid) unless self.unit.convertible_to? self.product.unit
    end
    if !self.second_warehouse.nil?
      errors.add(:warehouse_id, :warehouse_can_not_receive_product, :warehouse => self.second_warehouse.name, :product => self.product.name, :contained_product => self.second_warehouse.product.name) unless self.second_warehouse.can_receive?(self.product_id)
    end
    unless self.warehouse.can_receive?(self.product_id)
      errors.add(:warehouse_id, :warehouse_can_not_transfer_product, :warehouse => self.warehouse.name, :product => self.product.name, :contained_product => self.warehouse.product.name) if self.transfer?
      errors.add(:warehouse_id, :warehouse_can_not_waste_product, :warehouse => self.warehouse.name, :product => self.product.name, :contained_product => self.warehouse.product.name) if self.waste?
    end
    errors.add(:warehouse_id, :warehouses_can_not_be_identical) if self.warehouse_id == self.second_warehouse_id
  end

  def execute(moved_on = Date.today)
    self.class.transaction do
      self.moved_on = moved_on
      self.save!
    end
  end

end
