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
# == Table: stocks
#
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  critic_quantity_min :decimal(, )      default(0.0), not null
#  id                  :integer          not null, primary key
#  location_id         :integer          not null
#  lock_version        :integer          default(0), not null
#  name                :string(255)      
#  origin_id           :integer          
#  origin_type         :string(255)      
#  product_id          :integer          not null
#  quantity            :decimal(, )      default(0.0), not null
#  quantity_max        :decimal(, )      default(0.0), not null
#  quantity_min        :decimal(, )      default(1.0), not null
#  tracking_id         :integer          
#  unit_id             :integer          
#  updated_at          :datetime         not null
#  updater_id          :integer          
#  virtual_quantity    :decimal(, )      default(0.0), not null
#

class Stock < ActiveRecord::Base
  belongs_to :company
  belongs_to :location
  belongs_to :product
  belongs_to :tracking
  belongs_to :unit
  
  attr_readonly :company_id
  validates_presence_of :unit_id
  
  def before_validation
    self.unit_id ||= self.product.unit_id
    self.quantity_min = self.product.quantity_min if self.quantity_min.nil?
    self.critic_quantity_min = self.product.critic_quantity_min if self.critic_quantity_min.nil?
    self.quantity_max = self.product.quantity_max if self.quantity_max.nil?
    locations = Location.find_all_by_company_id(self.company_id)
    self.location_id = locations[0].id if locations.size == 1
  end

  def validate 
    if self.location
      errors.add_to_base(:product_cannot_be_in_location, :location=>self.location.name) unless self.location.can_receive(self.product_id)
    end
  end

  def label
    if self.tracking
      return tc(:label, :tracking=>self.tracking.name, :quantity=>self.virtual_quantity)
    else
      return tc(:no_tracking)
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
    stock = Stock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id})
    if stock.nil?
      ps = Stock.new(:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id, :quantity_min=>params[:quantity_min], :quantity_max=>params[:quantity_max], :critic_quantity_min=>params[:critic_quantity_min])
      ps.save
    else
      stock.update_attributes(params)
    end
  end

  #   def reflect_changes(quantity)
  #     old_quantity = self.quantity 
  #     if quantity.to_i != old_quantity
  #       input = old_quantity < quantity.to_i ? false : true
  #       #raise Exception.new input.inspect
  #       if input 
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(quantity.to_i - old_quantity), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true, :input=>input, :origin_type=>InventoryLine.to_s)
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(quantity.to_i - old_quantity), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false, :input=>input, :origin_type=>InventoryLine.to_s)
  #       else
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(old_quantity - quantity.to_i), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true, :input=>input, :origin_type=>InventoryLine.to_s)
  #         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(old_quantity - quantity.to_i), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false, :input=>input, :origin_type=>InventoryLine.to_s)
  #       end
  #     end
  #   end

  # def to_inventory_line(quantity, inventory_id)
  #   result = (self.quantity.to_f == quantity.to_f)
  #   puts self.quantity.to_f.inspect+quantity.to_f.inspect+result.inspect
  #   InventoryLine.create!(:product_id=>self.product_id, :location_id=>self.location_id, :inventory_id=>inventory_id, :theoric_quantity=>self.quantity, :quantity=>quantity, :company_id=>self.company_id)
  # end
  
end
 
