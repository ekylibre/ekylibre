# == Schema Information
# Schema version: 20090311124450
#
# Table name: deliveries
#
#  id                :integer       not null, primary key
#  order_id          :integer       not null
#  invoice_id        :integer       
#  shipped_on        :date          not null
#  delivered_on      :date          not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#  contact_id        :integer       
#

class Delivery < ActiveRecord::Base

  validates_presence_of :planned_on

  def before_validation
    self.amount = 0
    self.amount_with_taxes = 0
    for line in self.lines
      self.amount += line.amount
      self.amount_with_taxes += line.amount_with_taxes
    end
    self.moved_on = Date.today if self.planned_on == Date.today and self.nature == "exw"
  end

  def before_destroy
    for line in self.lines
      line.destroy
    end
  end

  def self.natures
    [:exw, :cpt, :cip].collect{|x| [tc('natures.'+x.to_s), x] }
  end
 
  def stocks_moves_create
    delivery_lines = DeliveryLine.find(:all, :conditions=>{:company_id=>self.company_id, :delivery_id=>self.id})
    for line in delivery_lines
      StockMove.create!(:name=>tc(:sale)+"  "+self.order.number, :quantity=>line.quantity, :location_id=>line.order_line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>Date.today, :company_id=>line.company_id, :virtual=>false, :input=>false)
      product = ProductsStock.find(:first, :conditions=>{:product_id=>line.product_id, :location_id=>line.order_line.location_id, :company_id=>line.company_id})
      product.update_attributes!(:current_real_quantity=>product.current_real_quantity - line.quantity)
    end
    self.moved_on = Date.today if self.moved_on.nil?
    self.save
  end

  def moment
    if self.planned_on <= Date.today-(3)
      css = "verylate"
    elsif self.planned_on <= Date.today
      css = "late"
  # elsif self.planned_on == Date.today
    # css = "today"
    elsif self.planned_on > Date.today
      css = "advance"
    end
    css
  end
  
end
