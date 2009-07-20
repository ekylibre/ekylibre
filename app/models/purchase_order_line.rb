# == Schema Information
#
# Table name: purchase_order_lines
#
#  id                :integer       not null, primary key
#  order_id          :integer       not null
#  product_id        :integer       not null
#  unit_id           :integer       not null
#  price_id          :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  position          :integer       
#  account_id        :integer       not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  lock_version      :integer       default(0), not null
#  location_id       :integer       
#  creator_id        :integer       
#  updater_id        :integer       
#

class PurchaseOrderLine < ActiveRecord::Base
  attr_readonly :company_id, :order_id

  belongs_to :account
  belongs_to :company
  belongs_to :product
  belongs_to :order, :class_name=>PurchaseOrder.to_s
  belongs_to :price
  belongs_to :location, :class_name=>StockLocation.to_s
  belongs_to :unit
  
  def before_validation
    check_reservoir = true
    self.account_id = self.price.product.charge_account_id
    self.unit_id = self.price.product.unit_id
    if self.price
      self.amount = (self.price.amount*self.quantity).round(2)
      self.amount_with_taxes = (self.price.amount_with_taxes*self.quantity).round(2)
    end
    if self.location
      if self.location.reservoir && self.location.product_id != self.product_id
        check_reservoir = false
        errors.add_to_base(tc(:stock_location_can_not_receive_product), :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name) 
      end
    end
    check_reservoir
  end
  
  
  def after_save
    self.order.refresh
  end
  
  def after_destroy
    #raise Exception.new "yyy"
    self.order.refresh
  end

  def product_name
    self.product.name
  end

end
