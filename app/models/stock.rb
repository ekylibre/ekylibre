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
# == Table: stocks
#
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  critic_quantity_min :decimal(16, 4)   default(0.0), not null
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string(255)      
#  product_id          :integer          not null
#  quantity            :decimal(16, 4)   default(0.0), not null
#  quantity_max        :decimal(16, 4)   default(0.0), not null
#  quantity_min        :decimal(16, 4)   default(1.0), not null
#  tracking_id         :integer          
#  unit_id             :integer          
#  updated_at          :datetime         not null
#  updater_id          :integer          
#  virtual_quantity    :decimal(16, 4)   default(0.0), not null
#  warehouse_id        :integer          not null
#


class Stock < CompanyRecord
  attr_readonly :unit_id, :product_id, :warehouse_id, :tracking_id
  belongs_to :warehouse
  belongs_to :product
  belongs_to :tracking
  belongs_to :unit
  has_many :moves, :class_name=>"StockMove"
  validates_presence_of :product, :warehouse, :unit, :quantity, :virtual_quantity
  validates_uniqueness_of :product_id, :scope=>[:tracking_id, :warehouse_id]
  
  before_validation do
    puts "#{self.class.name} 1"
    warehouses = self.company.warehouses
    self.warehouse = warehouses.first if warehouses.size == 1
    if self.product
      self.unit_id ||= self.product.unit_id
      self.quantity_min = self.product.quantity_min if self.quantity_min.nil?
      self.quantity_max = self.product.quantity_max if self.quantity_max.nil?
      self.critic_quantity_min = self.product.critic_quantity_min if self.critic_quantity_min.nil?
      self.name = tc(:default_name, :product=>self.product.name, :warehouse=>self.warehouse, :tracking=>(self.tracking ? self.tracking.name : "")) if self.name.blank? and self.warehouse
    end
    puts "#{self.class.name} 2"
    return true
  end

  validate do 
    puts "#{self.class.name} 3.1"
    if self.warehouse
      puts "#{self.class.name} 3.2"
      errors.add_to_base(:product_cannot_be_in_warehouse, :warehouse=>self.warehouse.name) unless self.warehouse.can_receive(self.product_id)
    end
    puts "#{self.class.name} 3.3"
    return true
  end

  def label
    if self.tracking
      return tc("label.with_tracking", :tracking=>self.tracking.name, :quantity=>self.virtual_quantity, :warehouse=>self.warehouse.name, :unit=>self.unit.name)
    else
      return tc("label.without_tracking", :quantity=>self.virtual_quantity, :warehouse=>self.warehouse.name, :unit=>self.unit.name)
    end
  end
  
  def state
    if self.virtual_quantity <= self.critic_quantity_min
      "critic"
    elsif self.virtual_quantity <= self.quantity_min
      "minimum"
    else
      "enough"
    end
  end

  def tracking_name
    return self.tracking ? self.tracking.name : ""
  end


  def add_or_update(params, product_id)
    stock = Stock.find(:first, :conditions=>{:company_id=>self.company_id, :warehouse_id=>params[:warehouse_id], :product_id=>product_id})
    if stock.nil?
      ps = Stock.new(:company_id=>self.company_id, :warehouse_id=>params[:warehouse_id], :product_id=>product_id, :quantity_min=>params[:quantity_min], :quantity_max=>params[:quantity_max], :critic_quantity_min=>params[:critic_quantity_min])
      ps.save
    else
      stock.update_attributes(params)
    end
  end

  protected

  def add_quantity(quantity, unit, virtual)
    # Convert quantity in stock unit
    quantity = self.unit.convert(quantity, unit)
    self.quantity += quantity unless virtual
    self.virtual_quantity += quantity
    self.save
  end

  def remove_quantity(quantity, unit, virtual)
    # Convert quantity in stock unit
    quantity = self.unit.convert(quantity, unit)
    self.quantity += quantity unless virtual
    self.virtual_quantity += quantity
    self.save
  end



  #   # Create a stock move
  #   def move(origin, options={})
  #     return true unless self.product.stockable?
  #     attributes = {}
  #     for attribute in [:quantity, :unit, :tracking, :warehouse, :product]
  #       attributes[attribute] = (options.has_key?(attribute) ? options[attribute] : origin.send(attribute))
  #     end
  #     attributes.merge!(:generated=>true, :company_id=>self.company_id, :origin=>origin)
  #     self.stock_moves.create!(attributes)
  #     attributes[:quantity] = -attributes[:quantity] unless incoming
  #     attributes[:warehouse_id] ||= self.stocks.first.warehouse_id if self.stocks.size > 0
  #     attributes[:planned_on] ||= Date.today
  #     attributes[:moved_on] ||= attributes[:planned_on] unless attributes.keys.include? :moved_on
  #     self.stock_moves.create!(attributes)
  #   end



  #   def reflect_changes(quantity)
  #     old_quantity = self.quantity 
  #     if quantity.to_i != old_quantity
  #       input = old_quantity < quantity.to_i ? false : true
  #       #raise Exception.new input.inspect
  #       if input 
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(quantity.to_i - old_quantity), :warehouse_id=>self.warehouse_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true, :input=>input, :origin_type=>InventoryLine.to_s)
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(quantity.to_i - old_quantity), :warehouse_id=>self.warehouse_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false, :input=>input, :origin_type=>InventoryLine.to_s)
  #       else
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(old_quantity - quantity.to_i), :warehouse_id=>self.warehouse_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true, :input=>input, :origin_type=>InventoryLine.to_s)
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(old_quantity - quantity.to_i), :warehouse_id=>self.warehouse_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false, :input=>input, :origin_type=>InventoryLine.to_s)
  #       end
  #     end
  #   end

  # def to_inventory_line(quantity, inventory_id)
  #   result = (self.quantity.to_f == quantity.to_f)
  #   puts self.quantity.to_f.inspect+quantity.to_f.inspect+result.inspect
  #   InventoryLine.create!(:product_id=>self.product_id, :warehouse_id=>self.warehouse_id, :inventory_id=>inventory_id, :theoric_quantity=>self.quantity, :quantity=>quantity, :company_id=>self.company_id)
  # end
  
end

