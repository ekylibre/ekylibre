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
#  comment      :text             
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  generated    :boolean          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  moved_on     :date             
#  name         :string(255)      not null
#  origin_id    :integer          
#  origin_type  :string(255)      
#  planned_on   :date             not null
#  product_id   :integer          not null
#  quantity     :decimal(16, 4)   not null
#  stock_id     :integer          
#  tracking_id  :integer          
#  unit_id      :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  virtual      :boolean          
#  warehouse_id :integer          not null
#


class StockMove < CompanyRecord
#   after_save :add_in_stock
#   after_destroy :remove_from_stock
#   before_update :remove_from_stock
  #   after_destroy :cancel
  #   after_save :move
  #   before_update :cancel
  belongs_to :warehouse
  belongs_to :origin, :polymorphic=>true
  belongs_to :product
  belongs_to :stock
  belongs_to :tracking
  belongs_to :unit
  
  validates_presence_of :stock, :product, :warehouse, :quantity, :unit

  before_validation do
    # caller.each{|l| puts ">> "+l}
    puts "#{self.class.name} 1"
    if origin
      code = [:name, :code, :number, :id].detect{|x| origin.respond_to? x}
      self.name ||= tc('default_name', :origin=>(origin ? origin.class.model_name.human : "*"), :code=>(origin ? origin.send(code) : "*"))
    end
    unless self.stock
      conditions = {:company_id=>self.company_id, :product_id=>self.product_id, :warehouse_id=>self.warehouse_id, :tracking_id=>self.tracking_id}
      self.stock = Stock.find_by_company_id_and_product_id_and_warehouse_id_and_tracking_id(self.company_id, self.product_id, self.warehouse_id, self.tracking_id) # self.company.stocks.where(conditions).first
      self.stock = self.company.stocks.create!(conditions) if stock.nil?
    end
    self.product ||= self.stock.product
    self.warehouse ||= self.stock.warehouse
    self.tracking ||= self.stock.tracking
    self.generated = false if self.generated.nil?
    self.unit_id ||= self.stock.unit_id
    puts "#{self.class.name} 2"
    # Add validation on unit correspondance
    return true
  end

  before_validation(:on=>:create) do
    puts "#{self.class.name} 3"
    self.planned_on = Date.today
    puts "#{self.class.name} 3.1"
    return true
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



  # Adds in stock the quantity
  def add_in_stock
    puts "#{self.class.name} 4"
    self.stock.add_quantity(self.quantity, self.unit, self.virtual)
    puts "#{self.class.name} 5"
    return true
  end

  # Removes from stock the old associated quantity
  def remove_from_stock
    puts "#{self.class.name} 6"
    old = self.class.find(self.id)
    old.stock.remove_quantity(old.quantity, old.unit, old.virtual)
    puts "#{self.class.name} 7"
    return true
  end

  private

  #   def move(quantity=nil, stock=nil, unit=nil)
  #     quantity ||= self.quantity
  #     stock ||= self.stock
  #     unit ||= self.unit
  #     # Convert to stock unit
  #     stock[quantity_column] += quantity * unit.coefficient / stock.unit.coefficient
  #     stock.save!
  #   end

  #   def cancel
  #     old_self = self.class.find(self.id) rescue self
  #     old_stock = Stock.find_by_id(old_self.stock_id)
  #     move(-old_self.quantity, old_stock, old_self.unit)
  #   end

  #   # Column to use in the product stock can be +:current_virtual_stock+ or +:current_real_stock+
  #   def quantity_column
  #     (self.virtual ? 'virtual_' : '')+"quantity"
  #   end

end


