# == Schema Information
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
#  virtual            :boolean       
#  input              :boolean       
#  generated          :boolean       
#  origin_type        :string(255)   
#  origin_id          :integer       
#

class StockMove < ActiveRecord::Base
  belongs_to :company
  belongs_to :location, :class_name=>StockLocation.to_s
  belongs_to :product
  belongs_to :tracking, :class_name=>StockTracking.to_s
  belongs_to :unit

  attr_readonly :company_id

  def before_validation
    self.unit_id = self.product.unit_id if self.product and self.unit.nil?
  end

  def before_create
    product_stock = ProductStock.find(:first, :conditions=>{:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id})
    product_stock = ProductStock.create!(:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id) if product_stock.nil?

    if self.virtual and self.input
      product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
    elsif self.virtual and !self.input
      product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity - self.quantity)
    elsif !self.virtual and self.input
      product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity + self.quantity)
    elsif !self.virtual and !self.input
      product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity - self.quantity)
    end

  end
  

  def before_update
    old_move = StockMove.find_by_id_and_company_id(self.id, self.company_id)
    old_product_stock = ProductStock.find(:first,:conditions=>{:product_id=>old_move.product_id, :location_id=>old_move.location_id, :company_id=>self.company_id})
    product_stock = ProductStock.find(:first, :conditions=>{:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id})
    product_stock = ProductStock.create!(:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id) if product_stock.nil?
    #raise Exception.new old_move.inspect+" <- old_move                   self-> "+self.inspect
    
    if old_move.location_id != self.location_id
      if self.input and self.virtual
        product_stock.update_attributes!(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
        old_product_stock.update_attributes!(:current_virtual_quantity=>old_product_stock.current_virtual_quantity - old_move.quantity)
      elsif self.input and !self.virtual
        product_stock.update_attributes!(:current_real_quantity=>product_stock.current_real_quantity + self.quantity)
        old_product_stock.update_attributes(:current_real_quantity=>old_product_stock.current_real_quantity - old_move.quantity) 
      elsif !self.input and self.virtual
        product_stock.update_attributes!(:current_virtual_quantity=>product_stock.current_virtual_quantity - self.quantity)
        old_product_stock.update_attributes!(:current_virtual_quantity=>old_product_stock.current_virtual_quantity + old_move.quantity)
      elsif !self.input and !self.virtual
        product_stock.update_attributes!(:current_real_quantity=>product_stock.current_real_quantity - self.quantity)
        old_product_stock.update_attributes(:current_real_quantity=>old_product_stock.current_real_quantity + old_move.quantity) 
      end
    else
      #raise Exception.new self.quantity.to_s+"  "+old_move.inspect+"  "+old_move.quantity.to_s+"                 "+product_stock.inspect
      if self.input and self.virtual
        product_stock.update_attributes!(:current_virtual_quantity=>product_stock.current_virtual_quantity + (self.quantity - old_move.quantity))
      elsif self.input and !self.virtual
        product_stock.update_attributes!(:current_real_quantity=>product_stock.current_real_quantity + (self.quantity - old_move.quantity) )
      elsif !self.input and self.virtual
        product_stock.update_attributes!(:current_virtual_quantity=>product_stock.current_virtual_quantity - (self.quantity - old_move.quantity))
      elsif !self.input and !self.virtual
        product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity - (self.quantity - old_move.quantity) )    
      end
    end
  end

  def before_destroy  
    product_stock = ProductStock.find(:first, :conditions=>{:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id})
    if self.virtual and self.input
      product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity - self.quantity)
    elsif self.virtual and !self.input
      product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
    elsif !self.virtual and self.input
      product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity - self.quantity)
    elsif !self.virtual and !self.input
      product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity + self.quantity)
    end
  end
  
  

  def self.natures
    [:virtual, :real].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  
  ### For stocks_moves created by user
#   def change_quantity
#     #self.virtual = true if self.virtual.nil?
#     #self.input = true if self.input.nil?
#     product_stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>self.location_id, :product_id=>self.product_id})
#     if product_stock.nil?
#       ProductStock.create!(:company_id=>self.company_id, :product_id=>self.product_id, :location_id=>self.location_id)
#     elsif self.moved_on.nil?
#       product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
#     else
#       product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
#       product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity + self.quantity)
#     end
#   end

#   ### For stocks_moves created by user
#   def update_stock_quantity(last_quantity)
#     product_stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>self.location_id, :product_id=>self.product_id})
#     if !self.moved_on.nil?
#       product_stock.update_attributes(:current_real_quantity=>product_stock.current_real_quantity + self.quantity, :current_virtual_quantity=>(product_stock.current_virtual_quantity + (self.quantity - last_quantity)) )
#     else
#       product_stock.update_attributes(:current_virtual_quantity=> product_stock.current_virtual_quantity + (self.quantity - last_quantity) )
#     end
#   end


end


