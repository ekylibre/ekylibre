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
# == Table: sales_orders
#
#  accounted_at        :datetime         
#  amount              :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes   :decimal(16, 2)   default(0.0), not null
#  annotation          :text             
#  client_id           :integer          not null
#  comment             :text             
#  company_id          :integer          not null
#  conclusion          :text             
#  confirmed_on        :date             
#  contact_id          :integer          
#  created_at          :datetime         not null
#  created_on          :date             not null
#  creator_id          :integer          
#  currency_id         :integer          
#  delivery_contact_id :integer          
#  downpayment_amount  :decimal(16, 2)   default(0.0), not null
#  expiration_id       :integer          not null
#  expired_on          :date             not null
#  function_title      :string(255)      
#  has_downpayment     :boolean          not null
#  id                  :integer          not null, primary key
#  introduction        :text             
#  invoice_contact_id  :integer          
#  journal_entry_id    :integer          
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  nature_id           :integer          not null
#  number              :string(64)       not null
#  paid_amount         :decimal(16, 2)   
#  payment_delay_id    :integer          not null
#  reference_number    :string(255)      
#  responsible_id      :integer          
#  state               :string(64)       default("O"), not null
#  subject             :string(255)      
#  sum_method          :string(8)        default("wt"), not null
#  transporter_id      :integer          
#  updated_at          :datetime         not null
#  updater_id          :integer          
#

class SalesOrder < ActiveRecord::Base
  acts_as_accountable 
  after_create {|r| r.client.add_event(:sales_order, r.updater_id)}
  attr_readonly :company_id, :created_on, :number
  belongs_to :client, :class_name=>Entity.to_s
  belongs_to :payer, :class_name=>Entity.to_s, :foreign_key=>:client_id
  belongs_to :company
  belongs_to :contact
  belongs_to :currency
  belongs_to :delivery_contact, :class_name=>Contact.to_s
  belongs_to :expiration, :class_name=>Delay.to_s
  belongs_to :invoice_contact, :class_name=>Contact.to_s
  # belongs_to :journal_entry
  belongs_to :nature, :class_name=>SalesOrderNature.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :responsible, :class_name=>User.name
  belongs_to :transporter, :class_name=>Entity.name
  has_many :deliveries, :class_name=>OutgoingDelivery.name, :dependent=>:destroy
  has_many :lines, :class_name=>SalesOrderLine.to_s, :foreign_key=>:order_id
  has_many :payment_uses, :as=>:expense, :class_name=>IncomingPaymentUse.name
  has_many :payments, :through=>:payment_uses
  has_many :sales_invoices
  has_many :stock_moves, :as=>:origin, :dependent=>:destroy
  has_many :subscriptions, :class_name=>Subscription.to_s
  validates_presence_of :client_id, :currency_id

  state_machine :state, :initial => :draft do
    state :draft
    state :ready
    state :refused
    state :processing
    state :invoiced
    state :finished
    state :aborted
    event :propose do
      transition :draft => :ready, :if=>:has_content?
    end
    event :correct do
      transition :ready => :draft
      transition :refused => :draft
      transition :processing => :draft, :if=>Proc.new{|so| so.paid_amount <= 0}
    end
    event :refuse do
      transition :ready => :refused, :if=>:has_content?
    end
    event :confirm do
      transition :ready => :processing, :if=>:has_content?
    end
    event :invoice do
      transition :processing => :invoiced, :if=>:has_content?
      transition :ready => :invoiced, :if=>:has_content?
    end
    event :finish do
      transition :invoiced => :finished
    end
    event :abort do
      transition [:draft, :ready] => :aborted # , :processing
    end
  end


  @@natures = [:estimate, :order, :invoice]
  
  def prepare
    self.currency_id ||= self.company.currencies.first.id if self.currency.nil? and self.company.currencies.count == 1

    self.paid_amount = self.payment_uses.sum(:amount)||0
    if self.number.blank?
      last = self.company.sales_orders.find(:first, :order=>"number desc")
      self.number = last ? last.number.succ! : '00000001'
    end
    if self.contact.nil? and self.client
      dc = self.client.default_contact
      self.contact_id = dc.id if dc
    end
    self.delivery_contact_id ||= self.contact_id
    self.invoice_contact_id  ||= self.delivery_contact_id
    self.created_on ||= Date.today
    self.nature ||= self.company.sales_order_natures.first if self.nature.nil? and self.company.sales_order_natures.count == 1
    if self.nature
      self.expiration_id ||= self.nature.expiration_id 
      self.expired_on ||= self.expiration.compute(self.created_on)
      self.payment_delay_id ||= self.nature.payment_delay_id 
      self.has_downpayment = self.nature.downpayment if self.has_downpayment.nil?
      self.downpayment_amount ||= self.amount_with_taxes*self.nature.downpayment_rate if self.amount_with_taxes>=self.nature.downpayment_minimum
    end

    self.sum_method = 'wt'
    if 1 # wt
      self.amount = 0
      self.amount_with_taxes = 0
      for line in self.lines
        self.amount += line.amount
        self.amount_with_taxes += line.amount_with_taxes
      end
    end
    true
  end
  
  def prepare_on_create
    self.created_on = Date.today
  end

  def clean_on_create
    specific_numeration = self.company.preference("management.sales_orders.numeration").value
    self.number = specific_numeration.next_value unless specific_numeration.nil?
  end
  
  def refresh
    self.save
  end

  def has_content?
    self.lines.size > 0
  end
  

  # Remove all bad dependencies and return at draft state with no stock moves, 
  # no deliveries, no payments and of course no invoices
  def correct(*args)
    return false unless self.can_correct?
#     for d in self.deliveries
#       d.mark_for_destruction
#       d.destroy
#     end
    self.deliveries.clear
    self.stock_moves.clear
    return super
  end

  # Confirm the sale order. This permits to reserve stocks before ship.
  # This method don't verify the stock moves.
  def confirm(validated_on=Date.today, *args)
    return false unless self.can_confirm
    for line in self.lines.find(:all, :conditions=>["quantity>0"])
      line.product.reserve_outgoing_stock(:origin=>line, :planned_on=>self.created_on)
    end
    self.reload.update_attributes!(:confirmed_on=>validated_on||Date.today)
    return super
  end
  

  # Create the last delivery with undelivered products if necessary.
  # The sale order is confirmed if it hasn't be done.
  def deliver
    self.confirm
    lines = []
    for line in self.lines.find_all_by_reduction_origin_id(nil)
      if quantity = line.undelivered_quantity > 0
        #raise Exception.new quantity.inspect+line.inspect
        lines << {:order_line_id=>line.id, :quantity=>line.quantity, :company_id=>self.company_id}
      end
    end
    if lines.size>0
      delivery = self.deliveries.create!(:amount=>0, :amount_with_taxes=>0, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :contact_id=>self.delivery_contact_id)
      for line in lines
        delivery.lines.create! line
      end
      self.refresh
    end
    self
  end


  # Invoice all the products creating the delivery if necessary. 
  def invoice(*args)
    return false unless self.can_invoice?
    ActiveRecord::Base.transaction do
      # Create sales invoice
      sales_invoice = self.sales_invoices.create!(:nature=>"S", :amount=>self.amount, :amount_with_taxes=>self.amount_with_taxes, :client_id=>self.client_id, :payment_delay_id=>self.payment_delay_id, :created_on=>Date.today, :contact_id=>self.invoice_contact_id)
      for line in self.lines
        sales_invoice.lines.create!(:order_line_id=>line.id, :amount=>line.amount, :amount_with_taxes=>line.amount_with_taxes, :quantity=>line.quantity)
      end
      # Move real stocks
      for line in self.lines
        line.product.move_outgoing_stock(:origin=>line, :quantity=>line.undelivered_quantity, :planned_on=>self.created_on)
      end
      # Accountize the sales invoice
      sales_invoice.to_accountancy if self.company.accountizing?
      return super
    end
    return false
  end

  # Invoice all the products creating the delivery if necessary. 
  def invoice2
    return false if self.lines.count <= 0
    ActiveRecord::Base.transaction do
      self.confirm
      self.reload
      # Create sales invoice
      sales_invoice = self.sales_invoices.create!(:company_id=>self.company_id, :nature=>"S", :amount=>self.amount, :amount_with_taxes=>self.amount_with_taxes, :client_id=>self.client_id, :payment_delay_id=>self.payment_delay_id, :created_on=>Date.today, :contact_id=>self.invoice_contact_id)
      for line in self.lines
        sales_invoice.lines.create!(:company_id=>line.company_id, :order_line_id=>line.id, :amount=>line.amount, :amount_with_taxes=>line.amount_with_taxes, :quantity=>line.quantity)
      end
      # Move real stocks
      for line in self.lines
        line.product.move_outgoing_stock(:origin=>line, :quantity=>line.undelivered_quantity, :planned_on=>self.created_on)
      end
      # Accountize the sales invoice
      sales_invoice.to_accountancy if self.company.accountizing?
      # Update sales_order state
      self.invoiced = true
      self.save!
      return true
    end
    return false
  end


  # Delivers all undelivered products and sales_invoice the order after. This operation cleans the order.
  def deliver_and_invoice
    self.deliver.invoice
  end

  # Duplicates a +sales_order+ in 'E' mode with its lines and its active subscriptions
  def duplicate(attributes={})
    fields = [:client_id, :nature_id, :currency_id, :letter_format, :annotation, :subject, :function_title, :introduction, :conclusion, :comment]
    hash = {}
    fields.each{|c| hash[c] = self.send(c)}
    copy = self.company.sales_orders.build(attributes.merge(hash))
    copy.save!
    if copy.save
      # Lines
      for line in self.lines.find(:all, :conditions=>["quantity>0"])
        copy.lines.create! :order_id=>copy.id, :product_id=>line.product_id, :quantity=>line.quantity, :location_id=>line.location_id, :company_id=>self.company_id
      end
      # Subscriptions
      for sub in self.subscriptions.find(:all, :conditions=>["NOT suspended"])
        copy.subscriptions.create!(:sales_order_id=>copy.id, :entity_id=>sub.entity_id, :contact_id=>sub.contact_id, :quantity=>sub.quantity, :nature_id=>sub.nature_id, :product_id=>sub.product_id, :company_id=>self.company_id)
      end
    else
      raise Exception.new(copy.errors.inspect)
    end
    copy
  end



  # Produces some amounts about the sale order.
  # Some options can be used:
  # - +:multi_sales_invoices+ adds the uninvoiced amount and invoiced amount
  # - +:with_balance+ adds the balance of the client of the sale order
  def stats(options={})
    invoiced_amount = self.invoiced_amount
    array = []
    array << [:client_balance, self.client.balance.to_s] if options[:with_balance]
    array << [:total_amount, self.amount_with_taxes]
    if options[:multi_sales_invoices]
      array << [:uninvoiced_amount, self.amount_with_taxes - invoiced_amount]
      array << [:invoiced_amount, invoiced_amount]
    end
    paid_amount = self.payment_uses.sum(:amount)
    array << [:paid_amount, paid_amount]
    array << [:unpaid_amount, invoiced_amount - paid_amount]
    array 
  end


  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end


  # Obsolete
  def text_state
    tc('states.'+self.state.to_s)+" DEPRECATION WARNING: Please use state_label in place of text_state"
  end
  
  # Prints human name of current state
  def state_label
    tc('states.'+self.state.to_s)
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:amount_with_taxes+
  def undelivered(column)
    sum  = self.send(column)
    # sum -= OutgoingDeliveryLine.sum(column, :joins=>"JOIN #{OutgoingDelivery.table_name} AS outgoing_deliveries ON (delivery_id=outgoing_deliveries.id)", :conditions=>["outgoing_deliveries.order_id=?", self.id])
    sum -= self.deliveries.sum(column)
    sum.round(2)
  end


  # Returns true if there is some products to deliver
  def deliverable?
    self.undelivered(:amount_with_taxes) > 0 and not self.invoiced?
  end


  # Computes unpaid amounts.
  def unpaid_amount(only_sales_invoices=true, only_received_payments=false)
    (only_sales_invoices ? self.invoiced_amount : self.amount_with_taxes).to_f - (only_received_payments ? self.payment_uses.sum(:amount, :conditions=>{:received=>true}) : self.payment_uses.sum(:amount)).to_f
  end

  def invoiced_amount
    self.sales_invoices.sum(:amount_with_taxes)
  end
  

  def payments
    sales_orders = self.client.sales_orders
    payment_uses = [] 
    for sales_order in sales_orders
      payment_uses += sales_order.payment_uses
    end
    payments = []
    for use in payment_uses
      found = false
      pay = self.company.payments.find(:all, :conditions=>["id = ? AND amount != used_amount", use.payment_id])
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


#   def status
#     status = ""
#     status = "critic" if self.invoiced? and self.paid_amount.to_f < self.amount_with_taxes
#     status
#   end


  def label
    # tc('label.'+(self.processing? or self.invoiced ? 'estimat-e' : 'order'), :number=>self.number)
    tc('label.'+self.state, :number=>self.number)
  end

  def letter?
    self.letter_format # and (self.ready? or self.draft?)
  end


  def address
    a = self.client.full_name+"\n"
    a += (self.contact ? self.contact.address : self.client.default_contact.address).gsub(/\s*\,\s*/, "\n")
    a
  end

  def number_label
    tc("number_label."+(self.estimate? ? 'proposal' : 'command'), :number=>self.number)
  end

  def taxes
    self.amount_with_taxes - self.amount
  end

  def usable_payments
    # self.company.payments.find(:all, :conditions=>["COALESCE(paid_amount,0)<COALESCE(amount,0) AND entity_id = ?" , self.payment_entity_id], :order=>"created_at desc")
    self.company.incoming_payments.find(:all, :conditions=>["COALESCE(paid_amount, 0)<COALESCE(amount, 0)"], :order=>"amount")
  end

  # Build general sales condition for the sale order
  def sales_conditions
    c = []
    c << tc('sales_conditions.downpayment', :percent=>100*self.nature.downpayment_rate, :amount=>(self.nature.downpayment_rate*self.amount_with_taxes).round(2)) if self.amount_with_taxes>self.nature.downpayment_minimum
    c << tc('sales_conditions.validity', :expiration=>::I18n.localize(self.expired_on, :format=>:legal))
    c += self.company.sales_conditions.to_s.split(/\s*\n\s*/)
    c += self.responsible.department.sales_conditions.to_s.split(/\s*\n\s*/) if self.responsible and self.responsible.department
    c
  end

  def unpaid_days
    #(self.sales_invoices.first.created_on - self.last_payment.paid_on) if self.last_payment and self.sales_invoices.first
    (Date.today - self.sales_invoices.first.created_on) if self.sales_invoices.first
  end

  def products
    p = []
    for line in self.lines
      p << line.product.name
    end
    ps = p.join(", ")
  end


  # this method accountizes the sale order.
  # In facts, it letters the sales_invoices and the payments
  def to_accountancy(action=:create, options={})
    self.class.update_all({:accounted_at=>Time.now}, {:id=>self.id})
    self.reload unless action == :destroy
  end

end


