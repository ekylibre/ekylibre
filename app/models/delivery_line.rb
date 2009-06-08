# == Schema Information
#
# Table name: delivery_lines
#
#  id                :integer       not null, primary key
#  delivery_id       :integer       not null
#  order_line_id     :integer       not null
#  product_id        :integer       not null
#  price_id          :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  unit_id           :integer       not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class DeliveryLine < ActiveRecord::Base

  belongs_to :company
  belongs_to :delivery
  belongs_to :price
  belongs_to :product
  belongs_to :order_line, :class_name=>SaleOrderLine.to_s
  belongs_to :unit
 

  def before_validation
    self.product = self.order_line.product
    self.amount = self.order_line.price.amount*self.quantity
    self.amount_with_taxes = self.order_line.price.amount_with_taxes*self.quantity
    self.price_id = self.order_line.price.id
    self.unit_id = self.order_line.unit.id
  end
  
  def validate_on_create
    #raise Exception.new self.undelivered_quantity.to_s+" "+self.quantity.to_s
    test = self.undelivered_quantity >= self.quantity 
    errors.add_to_base(tc:error_undelivered_quantity, :product=>self.product.name) if (self.undelivered_quantity < self.quantity)
  end
  
  def before_update
    line = DeliveryLine.find_by_id_and_company_id(self.id, self.company_id)
    errors.add_to_base tc(:error_undelivered_quantity, :product=>self.product.name) if (self.undelivered_quantity < ( self.quantity - line.quantity ))
    #test = (self.undelivered_quantity < ( self.quantity - line.quantity))
    #puts " undelivered       "+self.undelivered_quantity.to_s+"        self.quantity "+self.quantity.to_s+"     line.quantity "+line.quantity.to_s+" "+test.to_s
    #test = (self.undelivered_quantity < ( self.quantity - line.quantity))
    
    #raise Exception.new self.undelivered_quantity.to_s+" "+self.quantity.to_s+" - "+line.quantity.to_s+test.to_s
  end
  

  def after_save
    self.delivery.save
  end

  def after_destroy
    self.delivery.save
  end

  def undelivered_quantity
    self.order_line.undelivered_quantity
  end

  def product_name
    self.product.name
  end
  
end
