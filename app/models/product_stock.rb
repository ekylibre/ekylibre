# == Schema Information
#
# Table name: product_stocks
#
#  company_id               :integer       not null
#  created_at               :datetime      not null
#  creator_id               :integer       
#  critic_quantity_min      :decimal(16, 2 default(0.0), not null
#  current_real_quantity    :decimal(16, 2 default(0.0), not null
#  current_virtual_quantity :decimal(16, 2 default(0.0), not null
#  id                       :integer       not null, primary key
#  location_id              :integer       not null
#  lock_version             :integer       default(0), not null
#  product_id               :integer       not null
#  quantity_max             :decimal(16, 2 default(0.0), not null
#  quantity_min             :decimal(16, 2 default(1.0), not null
#  updated_at               :datetime      not null
#  updater_id               :integer       
#

class ProductStock < ActiveRecord::Base

  belongs_to :company
  belongs_to :product
  belongs_to :location, :class_name=>StockLocation.to_s
  
  def before_validation
    self.quantity_min = self.product.quantity_min if self.quantity_min.nil?
    self.critic_quantity_min = self.product.critic_quantity_min if self.critic_quantity_min.nil?
    self.quantity_max = self.product.quantity_max if self.quantity_max.nil?
    locations = StockLocation.find_all_by_company_id(self.company_id)
    self.location_id = locations[0].id if locations.size == 1
  end

   def validate 
     if self.location
       errors.add_to_base(tc(:error_azz_z, :location=>self.location.name)) unless self.location.can_receive(self.product_id)
     end
   end
  
  def state
    if self.current_virtual_quantity <= self.critic_quantity_min
      css = "critic"
    elsif self.current_virtual_quantity <= self.quantity_min
      css = "minimum"
    else
      css = "enough"
    end
    css
  end


  def add_or_update(params,product_id)
    stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id})
    if stock.nil?
      ps = ProductStock.new(:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id, :quantity_min=>params[:quantity_min], :quantity_max=>params[:quantity_max], :critic_quantity_min=>params[:critic_quantity_min])
      ps.save
    else
      stock.update_attributes(params)
    end
  end

#   def reflect_changes(quantity)
#     old_current_real_quantity = self.current_real_quantity 
#     if quantity.to_i != old_current_real_quantity
#       input = old_current_real_quantity < quantity.to_i ? false : true
#       #raise Exception.new input.inspect
#       if input 
#         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(quantity.to_i - old_current_real_quantity), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true, :input=>input, :origin_type=>InventoryLine.to_s)
#         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(quantity.to_i - old_current_real_quantity), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false, :input=>input, :origin_type=>InventoryLine.to_s)
#       else
#         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(old_current_real_quantity - quantity.to_i), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true, :input=>input, :origin_type=>InventoryLine.to_s)
#         StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(old_current_real_quantity - quantity.to_i), :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false, :input=>input, :origin_type=>InventoryLine.to_s)
#       end
#     end
#   end

  def reflect_changes(quantity, inventory_id)
    result = (self.current_real_quantity.to_f == quantity.to_f)
    puts self.current_real_quantity.to_f.inspect+quantity.to_f.inspect+result.inspect
    InventoryLine.create!(:product_id=>self.product_id, :location_id=>self.location_id, :inventory_id=>inventory_id, :theoric_quantity=>self.current_real_quantity, :validated_quantity=>quantity, :company_id=>self.company_id)
  end
  
end
