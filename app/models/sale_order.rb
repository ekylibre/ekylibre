# == Schema Information
# Schema version: 20090311124450
#
# Table name: sale_orders
#
#  id                  :integer       not null, primary key
#  client_id           :integer       not null
#  nature_id           :integer       not null
#  created_on          :date          not null
#  number              :string(64)    not null
#  sum_method          :string(8)     default("wt"), not null
#  invoiced            :boolean       not null
#  amount              :decimal(16, 2 default(0.0), not null
#  amount_with_taxes   :decimal(16, 2 default(0.0), not null
#  state               :string(1)     default("O"), not null
#  expiration_id       :integer       not null
#  expired_on          :date          not null
#  payment_delay_id    :integer       not null
#  has_downpayment     :boolean       not null
#  downpayment_amount  :decimal(16, 2 default(0.0), not null
#  contact_id          :integer       not null
#  invoice_contact_id  :integer       not null
#  delivery_contact_id :integer       not null
#  subject             :string(255)   
#  function_title      :string(255)   
#  introduction        :text          
#  conclusion          :text          
#  comment             :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#

class SaleOrder < ActiveRecord::Base
  
  attr_readonly :company_id, :created_on, :number

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

  def refresh
    self.save
  end


  def self.natures
    [:estimate, :order, :invoice].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  
  def stocks_moves_create
    for line in self.lines
      StockMove.create!(:name=>tc(:sale)+"  "+self.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.created_on, :company_id=>line.company_id, :virtual=>true, :input=>false)
    end
  end

  def change_quantity(virtual, input )
    for line in self.lines
      product = ProductStock.find(:first, :conditions=>{:product_id=>line.product_id, :location_id=>line.location_id, :company_id=>line.company_id})
      product = ProductStock.create!(:product_id=>line.product_id, :location_id=>line.location_id, :company_id=>line.company_id) if product.nil?
      if virtual and input
        product.update_attributes(:current_virtual_quantity=>product.current_virtual_quantity + line.quantity)
      elsif virtual and !input
        product.update_attributes(:current_virtual_quantity=>product.current_virtual_quantity - line.quantity)
      elsif !virtual and input
        product.update_attributes(:current_real_quantity=>product.current_real_quantity + line.quantity)
      elsif !virtual and !input
        product.update_attributes(:current_real_quantity=>product.current_real_quantity - line.quantity)
      end
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


