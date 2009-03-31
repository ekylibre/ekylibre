# == Schema Information
# Schema version: 20090311124450
#
# Table name: stock_moves
#
#  id                 :integer       not null, primary key
#  name               :string(255)   not null
#  planned_on         :date          not null
#  moved_on           :date          
#  quantity           :float         not null
#  comment            :text          
#  second_move_id     :integer       
#  second_location_id :integer       
#  tracking_id        :integer       
#  location_id        :integer       not null
#  unit_id            :integer       not null
#  product_id         :integer       not null
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  updated_at         :datetime      not null
#  created_by         :integer       
#  updated_by         :integer       
#  lock_version       :integer       default(0), not null
#

class StockMove < ActiveRecord::Base
  attr_readonly :company_id

  def before_validation
    self.unit_id = self.product.unit_id if self.product and self.unit.nil?
  end
  
  def change_quantity
    product_stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>self.location_id, :product_id=>self.product_id})
    if product_stock.nil?
      ProductStock.create!(:company_id=>self.company_id, :product_id=>self.product_id, :location_id=>self.location_id)
    elsif self.moved_on.nil?
      product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
    else
      product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
      product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity + self.quantity)
    end
  end

  def update_stock_quantity(last_quantity)
    product_stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>self.location_id, :product_id=>self.product_id})
    if !self.moved_on.nil?
      product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity + self.quantity, :current_virtual_quantity=>(product_stock.current_virtual_quantity + (self.quantity - last_quantity)) )
    else
      product_stock.update_attributes(:current_virtual_quantity=> product_stock.current_virtual_quantity + (self.quantity - last_quantity) )
    end
  end


end


