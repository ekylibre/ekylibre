# == Schema Information
#
# Table name: deliveries
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  comment           :text          
#  company_id        :integer       not null
#  contact_id        :integer       
#  created_at        :datetime      not null
#  creator_id        :integer       
#  currency_id       :integer       
#  id                :integer       not null, primary key
#  invoice_id        :integer       
#  lock_version      :integer       default(0), not null
#  mode_id           :integer       
#  moved_on          :date          
#  order_id          :integer       not null
#  planned_on        :date          
#  transport_id      :integer       
#  transporter_id    :integer       
#  updated_at        :datetime      not null
#  updater_id        :integer       
#  weight            :decimal(, )   
#

class Delivery < ActiveRecord::Base
  belongs_to :company
  belongs_to :contact
  belongs_to :invoice
  belongs_to :mode, :class_name=>DeliveryMode.name
  belongs_to :order, :class_name=>SaleOrder.name
  belongs_to :transport
  has_many :lines, :class_name=>DeliveryLine.name 
  has_many :stock_moves, :as=>:origin

  attr_readonly :company_id, :order_id
  validates_presence_of :planned_on

  def before_validation
    self.amount = 0
    self.amount_with_taxes = 0
    for line in self.lines
      self.amount += line.amount
      self.amount_with_taxes += line.amount_with_taxes
    end
#     if !self.mode.nil?
#       self.moved_on = Date.today if self.planned_on == Date.today and self.mode.code == "exw"
#     end
  end

  def before_destroy
    for line in self.lines
      line.destroy
    end
  end

  def before_save
    self.weight = 0
    for line in self.lines
      self.weight += (line.product.weight||0)*line.quantity
    end
  end

  def after_save
    self.transport.refresh if self.transport
  end

  def self.natures
    [:exw, :cpt, :cip].collect{|x| [tc('natures.'+x.to_s), x] }
  end
 

  # Ships the delivery and move the real stocks. This operation locks the delivery.
  # This permits to manage stocks.
  def ship(shipped_on=Date.today)
    for line in self.lines.find(:all, :conditions=>["quantity>0"])
      # self.stock_moves.create!(:name=>tc(:sale, :number=>self.order.number), :quantity=>line.quantity, :location_id=>line.order_line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>shipped_on, :company_id=>line.company_id, :virtual=>false, :input=>false, :origin_type=>Delivery.to_s, :origin_id=>self.id, :generated=>true)
      line.product.take_stock_out(line.quantity, :location_id=>line.order_line.location_id, :planned_on=>self.planned_on, :moved_on=>shipped_on)
    end
    self.moved_on = shipped_on if self.moved_on.nil?
    self.save
  end
  
  def moment
    if self.planned_on <= Date.today-(3)
      "verylate"
    elsif self.planned_on <= Date.today
      "late"
    elsif self.planned_on > Date.today
      "advance"
    end
  end

  def label
    tc('label', :client=>self.order.client.full_name.to_s, :address=>self.contact.address.to_s)
  end

  # Used with dyta for the moment
  def quantity
    ''
  end

  def text_nature
    tc('natures.'+self.nature.to_s)
  end

  def contact_address
    self.contact.address if self.contact 
  end

end
