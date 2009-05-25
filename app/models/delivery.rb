# == Schema Information
# Schema version: 20090512102847
#
# Table name: deliveries
#
#  id                :integer       not null, primary key
#  order_id          :integer       not null
#  invoice_id        :integer       
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
#  planned_on        :date          
#  moved_on          :date          
#  mode_id           :integer       
#

class Delivery < ActiveRecord::Base

  belongs_to :company
  belongs_to :contact
  belongs_to :invoice
  belongs_to :mode, :class_name=>DeliveryMode.to_s
  belongs_to :order, :class_name=>SaleOrder.to_s
  has_many :lines, :class_name=>DeliveryLine.to_s 

  validates_presence_of :planned_on

  def before_validation
    self.amount = 0
    self.amount_with_taxes = 0
    for line in self.lines
      self.amount += line.amount
      self.amount_with_taxes += line.amount_with_taxes
    end
    if !self.mode.nil?
      self.moved_on = Date.today if self.planned_on == Date.today and self.mode.code == "exw"
    end
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
      if line.quantity > 0
        StockMove.create!(:name=>tc(:sale)+"  "+self.order.number, :quantity=>line.quantity, :location_id=>line.order_line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>Date.today, :company_id=>line.company_id, :virtual=>false, :input=>false, :origin_type=>Delivery.to_s, :origin_id=>self.id, :generated=>true)
      end
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

  # Used with dyta for the moment
  def quantity
    ''
  end

  def text_nature
    tc('natures.'+self.nature.to_s)
  end

end
