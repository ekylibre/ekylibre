# == Schema Information
#
# Table name: delivery_lines
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  delivery_id       :integer       not null
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  order_line_id     :integer       not null
#  price_id          :integer       not null
#  product_id        :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  unit_id           :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

class DeliveryLine < ActiveRecord::Base
  belongs_to :company
  belongs_to :delivery
  belongs_to :price
  belongs_to :product
  belongs_to :order_line, :class_name=>SaleOrderLine.name
  belongs_to :unit
 
  attr_readonly :company_id, :order_line_id, :product_id, :price_id, :unit_id

  def before_validation
    self.product_id = self.order_line.product_id
    self.price_id = self.order_line.price.id
    self.unit_id = self.order_line.unit_id
    self.amount = self.order_line.price.amount*self.quantity
    self.amount_with_taxes = self.order_line.price.amount_with_taxes*self.quantity
  end
  
  def validate_on_create
    # raise Exception.new self.undelivered_quantity.to_s+" "+self.quantity.to_s
    # test = self.undelivered_quantity >= self.quantity 
    if self.product
      errors.add_to_base(tc(:error_undelivered_quantity, :product=>self.product_name)) if (self.undelivered_quantity < self.quantity)
    end
  end
  
  def before_update
    line = DeliveryLine.find_by_id_and_company_id(self.id, self.company_id)
    errors.add_to_base tc(:error_undelivered_quantity, :product=>self.product.name) if (self.undelivered_quantity < ( self.quantity - line.quantity ))
    #test = (self.undelivered_quantity < ( self.quantity - line.quantity))
    #test = (self.undelivered_quantity < ( self.quantity - line.quantity))
    
    #raise Exception.new self.undelivered_quantity.to_s+" "+self.quantity.to_s+" - "+line.quantity.to_s+test.to_s
  end

  def after_save
    self.delivery.save
  end

  def after_destroy
   # raise Exception.new self.inspect
    #self.delivery.save
  end

  def undelivered_quantity
    self.order_line.undelivered_quantity
  end

  def product_name
    self.product.name
  end
  
end
