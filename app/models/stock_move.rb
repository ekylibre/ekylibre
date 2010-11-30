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
# == Table: stock_moves
#
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  generated           :boolean          
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  moved_on            :date             
#  name                :string(255)      not null
#  origin_id           :integer          
#  origin_type         :string(255)      
#  planned_on          :date             not null
#  product_id          :integer          not null
#  quantity            :decimal(16, 4)   not null
#  second_move_id      :integer          
#  second_warehouse_id :integer          
#  stock_id            :integer          
#  tracking_id         :integer          
#  unit_id             :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#  virtual             :boolean          
#  warehouse_id        :integer          not null
#


class StockMove < CompanyRecord
  after_destroy :cancel
  after_save :move
  before_update :cancel
  belongs_to :company
  belongs_to :warehouse
  belongs_to :origin, :polymorphic=>true
  belongs_to :product
  belongs_to :stock
  belongs_to :tracking
  belongs_to :unit

  attr_readonly :company_id, :virtual
  
  validates_presence_of :generated, :stock_id, :company_id, :product_id, :warehouse_id, :stock_id, :quantity, :unit_id

  before_validation do
    self.generated = false if self.generated.nil?
    self.stock = Stock.find(:first, :conditions=>{:product_id=>self.product_id, :warehouse_id=>self.warehouse_id, :company_id=>self.company_id, :tracking_id=>self.tracking_id})
    self.stock = Stock.create!(:product_id=>self.product_id, :warehouse_id=>self.warehouse_id, :company_id=>self.company_id, :tracking_id=>self.tracking_id) if stock.nil?
    self.unit_id ||= self.product.unit_id if self.product
    # Add validation on unit correspondance
  end
  
  def self.natures
    [:virtual, :real].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def state
    if self.quantity > 0
      "notice"
    elsif self.quantity < 0
      "error"
    end
  end

  private

  def move(quantity=nil, stock=nil, unit=nil)
    quantity ||= self.quantity
    stock ||= self.stock
    unit ||= self.unit
    # Convert to stock unit
    stock[quantity_column] += quantity * unit.coefficient / stock.unit.coefficient
    stock.save!
  end

  def cancel
    old_self = self.class.find(self.id) rescue self
    old_stock = Stock.find_by_id(old_self.stock_id)
    move(-old_self.quantity, old_stock, old_self.unit)
  end

  # Column to use in the product stock can be +:current_virtual_stock+ or +:current_real_stock+
  def quantity_column
    (self.virtual ? 'virtual_' : '')+"quantity"
  end

end


