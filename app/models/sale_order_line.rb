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
# == Table: sale_order_lines
#
#  account_id          :integer          not null
#  amount              :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes   :decimal(16, 2)   default(0.0), not null
#  annotation          :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  entity_id           :integer          
#  id                  :integer          not null, primary key
#  invoiced            :boolean          not null
#  label               :text             
#  location_id         :integer          
#  lock_version        :integer          default(0), not null
#  order_id            :integer          not null
#  position            :integer          
#  price_amount        :decimal(16, 2)   
#  price_id            :integer          not null
#  product_id          :integer          not null
#  quantity            :decimal(16, 4)   default(1.0), not null
#  reduction_origin_id :integer          
#  tax_id              :integer          
#  tracking_id         :integer          
#  unit_id             :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#

class SaleOrderLine < ActiveRecord::Base
  belongs_to :account
  belongs_to :company
  belongs_to :entity
  belongs_to :location, :class_name=>StockLocation.to_s
  belongs_to :order, :class_name=>SaleOrder.to_s
  belongs_to :price
  belongs_to :product
  belongs_to :reduction_origin, :class_name=>SaleOrderLine.to_s
  belongs_to :tax
  belongs_to :tracking
  belongs_to :unit
  has_one :reduction, :class_name=>SaleOrderLine.to_s, :foreign_key=>:reduction_origin_id
  has_many :delivery_lines, :foreign_key=>:order_line_id
  has_many :invoice_lines
  acts_as_list :scope=>:order
  
  validates_presence_of :price_id

  attr_readonly :company_id, :order_id
  
  def before_validation
    # check_reservoir = true
    self.company_id = self.order.company_id if self.order
    if not self.price and self.order and self.product
      self.price = self.product.default_price(order.client.category_id)
      #raise Exception.new self.inspect 
      @test = true
    end
    self.product = self.price.product if self.price
    if self.product
      self.account_id = self.product.product_account_id 
      self.unit_id = self.product.unit_id
      if self.product.manage_stocks
        self.location_id ||= self.product.stocks.first.location_id
      else
        self.location_id = nil
      end
    end
    self.account_id ||= 0
    self.price_amount ||= 0

    reduction_rate = self.order.client.max_reduction_rate

    if self.price_amount > 0
      price = Price.create!(:amount=>self.price_amount, :tax_id=>self.tax.id, :entity_id=>self.company.entity_id , :company_id=>self.company_id, :active=>false, :product_id=>self.product_id, :category_id=>self.order.client.category_id)
      self.price = price
    end
    
    if self.price
      if self.reduction_origin_id.nil?
        if self.quantity
          self.amount = (self.price.amount*self.quantity).round(2)
          self.amount_with_taxes = (self.price.amount_with_taxes*self.quantity).round(2) 
        elsif self.amount
          q = self.amount/self.price.amount
          self.quantity = q.round(2)
          self.amount_with_taxes = (q*self.price.amount_with_taxes).round(2)
        elsif self.amount_with_taxes
          #raise Exception.new "okkk"+self.inspect if @test
          q = self.amount_with_taxes/self.price.amount_with_taxes
          self.quantity = q.round(2)
          self.amount = (q*self.price.amount).round(2)
        end
      else
        self.quantity = -reduction_rate*self.reduction_origin.quantity
        self.amount   = -reduction_rate*self.reduction_origin.amount       
        self.amount_with_taxes = -reduction_rate*self.reduction_origin.amount_with_taxes
      end
    end

    if self.reduction_origin_id.nil?
      self.label = self.product.catalog_name
    else
      self.label = tc('reduction_on', :product=>self.product.catalog_name, :rate=>reduction_rate, :percent=>reduction_rate*100, :amount=>self.amount_with_taxes-self.reduction_origin.amount_with_taxes)
    end
    
    #     if self.location.reservoir && self.location.product_id != self.product_id
    #       check_reservoir = false
    #       errors.add_to_base(tc(:stock_location_can_not_transfer_product), :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name, :account_id=>0, :unit_id=>self.unit_id) 
    #     end
    #     check_reservoir
  end

  
  def after_save
    reduction_rate = self.order.client.max_reduction_rate
    if reduction_rate > 0 and self.product.reduction_submissive and self.reduction_origin_id.nil?
      reduction = self.reduction || self.build_reduction
      reduction.attributes = {:company_id=>self.company_id, :reduction_origin_id=>self.id, :price_id=>self.price_id, :product_id=>self.product_id, :order_id=>self.order_id, :location_id=>self.location_id, :quantity=>-self.quantity*reduction_rate}
      reduction.save!
    elsif self.reduction
      self.reduction.destroy
    end
    self.order.reload.refresh if self.reduction_origin.nil?
  end
  
  def after_destroy
    self.reduction.delete if self.reduction
    self.order.reload.refresh 
  end

  def validate
    if self.location
      errors.add_to_base(tc(:stock_location_can_not_transfer_product, :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name)) unless self.location.can_receive?(self.product_id)
      if self.tracking
        stock = self.company.stocks.find(:first, :conditions=>{:product_id=>self.product_id, :location_id=>self.location_id, :tracking_id=>self.tracking_id})
        errors.add_to_base(tc(:can_not_use_this_tracking, :name=>self.tracking.name)) if stock and stock.virtual_quantity < self.quantity
      end
    end
    if self.price
      errors.add_to_base(tc(:currency_is_not_sale_order_currency)) if self.price.currency_id != self.order.currency_id
    end
  end
  
  def undelivered_quantity
    self.quantity - self.delivery_lines.sum(:quantity)
  end

  def product_name
    self.product ? self.product.name : tc(:no_product) 
  end

  def designation
    d  = self.label
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d
  end

  def subscription?
    self.product.nature == "subscrip"
  end

  def new_subscription(attributes={})
    #raise Exception.new attributes.inspect
    subscription = Subscription.new((attributes||{}).merge(:sale_order_id=>self.order.id, :company_id=>self.company.id, :product_id=>self.product_id, :nature_id=>self.product.subscription_nature_id))
    subscription.attributes = attributes
    product = subscription.product
    nature  = subscription.nature
    if nature
      if nature.nature == "period"
        subscription.started_on ||= Date.today
        subscription.stopped_on ||= Delay.compute((product.subscription_period||'1 year')+", 1 day ago", subscription.started_on)
      else
        subscription.first_number ||= nature.actual_number
        subscription.last_number  ||= subscription.first_number+(product.subscription_quantity||1)-1
      end
    end
    subscription.quantity   ||= 1
    subscription.contact_id ||= self.order.contact_id
    subscription.entity_id  ||= subscription.contact.entity_id if subscription.contact
    subscription
  end


  def taxes
    self.amount_with_taxes - self.amount
  end

end
