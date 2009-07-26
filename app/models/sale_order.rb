# == Schema Information
#
# Table name: sale_orders
#
#  amount              :decimal(16, 2 default(0.0), not null
#  amount_with_taxes   :decimal(16, 2 default(0.0), not null
#  client_id           :integer       not null
#  comment             :text          
#  company_id          :integer       not null
#  conclusion          :text          
#  confirmed_on        :date          
#  contact_id          :integer       not null
#  created_at          :datetime      not null
#  created_on          :date          not null
#  creator_id          :integer       
#  delivery_contact_id :integer       not null
#  downpayment_amount  :decimal(16, 2 default(0.0), not null
#  expiration_id       :integer       not null
#  expired_on          :date          not null
#  function_title      :string(255)   
#  has_downpayment     :boolean       not null
#  id                  :integer       not null, primary key
#  introduction        :text          
#  invoice_contact_id  :integer       not null
#  invoiced            :boolean       not null
#  lock_version        :integer       default(0), not null
#  nature_id           :integer       not null
#  number              :string(64)    not null
#  payment_delay_id    :integer       not null
#  state               :string(1)     default("O"), not null
#  subject             :string(255)   
#  sum_method          :string(8)     default("wt"), not null
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

class SaleOrder < ActiveRecord::Base
  
  attr_readonly :company_id, :created_on, :number

  belongs_to :company
  belongs_to :invoice_contact, :class_name=>Contact.to_s
  belongs_to :delivery_contact,:class_name=>Contact.to_s
  belongs_to :contact
  belongs_to :expiration, :class_name=>Delay.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :client, :class_name=>Entity.to_s
  belongs_to :nature, :class_name=>SaleOrderNature.to_s
  has_many :deliveries, :foreign_key=>:order_id
  has_many :invoices
  has_many :payment_parts, :foreign_key=>:order_id
  has_many :lines, :class_name=>SaleOrderLine.to_s, :foreign_key=>:order_id
  
  def before_validation
    if self.number.blank?
      last = self.client.sale_orders.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end
    self.created_on ||= Date.today
    if self.nature
      self.expiration_id ||= self.nature.expiration_id 
      self.expired_on ||= self.expiration.compute(self.created_on)
      self.payment_delay_id ||= self.nature.payment_delay_id 
      if self.has_downpayment.nil?
        self.has_downpayment = self.nature.downpayment
      end
      
      self.downpayment_amount ||= self.amount_with_taxes*self.nature.downpayment_rate if self.amount_with_taxes>=self.nature.downpayment_minimum
    end

    if 1 # wt
      self.amount = 0
      self.amount_with_taxes = 0
      for line in self.lines
        self.amount += line.amount
        self.amount_with_taxes += line.amount_with_taxes
      end
    else
      
    end

  end

  def before_validation_on_create
    self.created_on = Date.today
  end

  def after_validation_on_create
    specific_numeration = self.company.parameter("management.sale_orders.numeration").value
    if not specific_numeration.nil?
      self.number = specific_numeration.next_value
    end
  end
  
  def refresh
    self.save
  end


  def self.natures
    [:estimate, :order, :invoice].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def text_state
    tc('states.'+self.state.to_s)
  end

  def stocks_moves_create
    for line in self.lines
      StockMove.create!(:name=>tc(:sale)+"  "+self.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.created_on, :company_id=>line.company_id, :virtual=>true, :input=>false, :origin_type=>SaleOrder.to_s, :origin_id=>self.id, :generated=>true)
    end
  end

  def undelivered(column)
    sum = 0
    if column == "amount"
      for line in self.lines
        sum += line.price.amount*line.undelivered_quantity
      end
    elsif column == "amount_with_taxes"
       for line in self.lines
        sum += line.price.amount_with_taxes*line.undelivered_quantity
       end
    end
    sum
  end

  def rest_to_pay
    ( self.invoices.sum(:amount_with_taxes,:conditions=>{:sale_order_id=>self.id,:company_id=>self.company_id}) - PaymentPart.sum(:amount, :conditions=>{:order_id=>self.id,:company_id=>self.company_id}) ).to_f
  end

  def add_payment(payment)
    if payment.amount > self.rest_to_pay
      payment.update_attributes!(:part_amount=>self.rest_to_pay)
      part = PaymentPart.new(:amount=>self.rest_to_pay,:order_id=>self.id,:company_id=>self.company_id,:payment_id=>payment.id)
      part.save!
    else
      part = PaymentPart.new(:amount=>payment.amount, :order_id=>self.id, :company_id=>self.company_id, :payment_id=>payment.id)
      part.save!
      payment.update_attributes!(:part_amount=>payment.amount) 
    end
  end

  def add_part(payment)
    if self.rest_to_pay > (payment.amount - payment.part_amount)
      puts payment.amount.to_s+" amount pay"+"     part amount payment"+payment.part_amount.to_s
      PaymentPart.create!(:amount=>(payment.amount - payment.part_amount),:order_id=>self.id,:company_id=>self.company_id,:payment_id=>payment.id)
      payment.update_attributes!(:part_amount=>(payment.amount))
    else
      puts payment.amount.to_s+" amount pay"+"     part amount payment"+payment.part_amount.to_s
      payment.update_attributes!(:part_amount=>( payment.part_amount + self.rest_to_pay))
      PaymentPart.create!(:amount=>self.rest_to_pay,:order_id=>self.id,:company_id=>self.company_id,:payment_id=>payment.id)
    end
  end

  def payments
    sale_orders = self.client.sale_orders
    payment_parts = [] 
    for sale_order in sale_orders
      payment_parts += sale_order.payment_parts
    end
    payments = []
    for part in payment_parts
      found = false
      pay = Payment.find(:all, :conditions=>["company_id = ? AND id = ? AND amount != part_amount",self.company_id ,part.payment_id])
     
      if !pay.empty? 
        for payment in payments
          found = true if payment.id == pay[0].id 
        end
        payments += pay if (!pay.nil? and !found)
        puts payments.inspect
      end
    end
    payments
  end

end


