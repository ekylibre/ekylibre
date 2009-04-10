# == Schema Information
# Schema version: 20090410102120
#
# Table name: sale_order_lines
#
#  id                :integer       not null, primary key
#  order_id          :integer       not null
#  product_id        :integer       not null
#  price_id          :integer       not null
#  invoiced          :boolean       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  unit_id           :integer       not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  position          :integer       
#  account_id        :integer       not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#  location_id       :integer       
#

class SaleOrderLine < ActiveRecord::Base
  attr_readonly :company_id, :order_id

  belongs_to :company
  belongs_to :account
  belongs_to :price
  belongs_to :order, :class_name=>SaleOrder.to_s
  belongs_to :product
  belongs_to :unit
  belongs_to :location, :class_name=>StockLocation.to_s
  has_many :delivery_lines
  has_many :invoice_lines
  
  def before_validation
    self.account_id = self.product.account_id
    self.unit_id = self.product.unit_id
    if self.price
      self.amount = (self.price.amount*self.quantity).round(2)
      self.amount_with_taxes = (self.price.amount_with_taxes*self.quantity).round(2)
    end
  end
  
  def validate
    #errors.add_to_base(tc(:error_no_found_price)) if self.price.nil?
  end
  
  def after_save
    self.order.refresh
  end

  def undelivered_quantity
    lines =  DeliveryLine.find(:all, :conditions=>{:company_id=>self.company_id, :order_line_id=>self.id})
    if lines.nil?
      rest = self.quantity
    else
      sum = 0
      for line in lines 
        sum += line.quantity
      end
      rest = (self.quantity - sum )
    end
    rest
  end

end
