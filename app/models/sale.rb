# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: sales
#
#  accounted_at        :datetime         
#  amount              :decimal(16, 2)   default(0.0), not null
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
#  credit              :boolean          not null
#  currency_id         :integer          
#  delivery_contact_id :integer          
#  downpayment_amount  :decimal(16, 2)   default(0.0), not null
#  expiration_id       :integer          
#  expired_on          :date             
#  function_title      :string(255)      
#  has_downpayment     :boolean          not null
#  id                  :integer          not null, primary key
#  initial_number      :string(64)       
#  introduction        :text             
#  invoice_contact_id  :integer          
#  invoiced_on         :date             
#  journal_entry_id    :integer          
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  lost                :boolean          not null
#  nature_id           :integer          
#  number              :string(64)       not null
#  origin_id           :integer          
#  paid_amount         :decimal(16, 2)   not null
#  payment_delay_id    :integer          not null
#  payment_on          :date             
#  pretax_amount       :decimal(16, 2)   default(0.0), not null
#  reference_number    :string(255)      
#  responsible_id      :integer          
#  state               :string(64)       default("O"), not null
#  subject             :string(255)      
#  sum_method          :string(8)        default("wt"), not null
#  transporter_id      :integer          
#  updated_at          :datetime         not null
#  updater_id          :integer          
#


class Sale < CompanyRecord
  acts_as_numbered :number, :readonly=>false
  after_create {|r| r.client.add_event(:sale, r.updater_id)}
  attr_readonly :company_id, :created_on
  attr_protected :pretax_amount, :amount
  belongs_to :client, :class_name=>"Entity"
  belongs_to :payer, :class_name=>"Entity", :foreign_key=>:client_id
  belongs_to :company
  belongs_to :contact
  belongs_to :currency
  belongs_to :delivery_contact, :class_name=>"Contact"
  belongs_to :expiration, :class_name=>"Delay"
  belongs_to :invoice_contact, :class_name=>"Contact"
  belongs_to :journal_entry
  belongs_to :nature, :class_name=>"SaleNature"
  belongs_to :origin, :class_name=>"Sale"
  belongs_to :payment_delay, :class_name=>"Delay"
  belongs_to :responsible, :class_name=>"User"
  belongs_to :transporter, :class_name=>"Entity"
  has_many :credits, :class_name=>"Sale", :foreign_key=>:origin_id
  has_many :deliveries, :class_name=>"OutgoingDelivery", :dependent=>:destroy
  has_many :lines, :class_name=>"SaleLine", :foreign_key=>:sale_id, :dependent=>:destroy, :order=>"position, id"
  has_many :payment_uses, :as=>:expense, :class_name=>"IncomingPaymentUse", :dependent=>:destroy
  has_many :payments, :through=>:payment_uses
  has_many :subscriptions, :class_name=>"Subscription"
  has_many :uses, :as=>:expense, :class_name=>"IncomingPaymentUse", :dependent=>:destroy
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :downpayment_amount, :paid_amount, :pretax_amount, :allow_nil => true
  validates_length_of :sum_method, :allow_nil => true, :maximum => 8
  validates_length_of :initial_number, :number, :state, :allow_nil => true, :maximum => 64
  validates_length_of :function_title, :reference_number, :subject, :allow_nil => true, :maximum => 255
  validates_inclusion_of :credit, :has_downpayment, :letter_format, :lost, :in => [true, false]
  validates_presence_of :amount, :client, :company, :created_on, :downpayment_amount, :number, :paid_amount, :payer, :payment_delay, :pretax_amount, :state, :sum_method
  #]VALIDATORS]
  validates_presence_of :client_id, :currency_id
  validates_presence_of :invoiced_on, :if=>Proc.new{|s| s.invoice?}

  state_machine :state, :initial => :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted

    event :propose do
      transition :draft => :estimate, :if=>:has_content?
    end
    event :correct do
      transition :estimate => :draft
      transition :refused => :draft
      transition :order => :draft, :if=>Proc.new{|so| so.paid_amount <= 0}
    end
    event :refuse do
      transition :estimate => :refused, :if=>:has_content?
    end
    event :confirm do
      transition :estimate => :order, :if=>:has_content?
    end
    event :invoice do
      transition :order => :invoice, :if=>:has_content?
      transition :estimate => :invoice, :if=>:has_content_not_deliverable?
    end
    event :abort do
      # transition [:draft, :estimate] => :aborted # , :order
      transition :draft => :aborted # , :order
    end
  end


  @@natures = [:estimate, :order, :invoice]
  
  before_validation do
    self.currency_id ||= self.company.currencies.first.id if self.currency.nil? and self.company.currencies.count == 1

    self.paid_amount = self.payment_uses.sum(:amount)||0
    self.paid_amount -= self.credits.sum(:amount)||0
    if self.contact.nil? and self.client
      dc = self.client.default_contact
      self.contact_id = dc.id if dc
    end
    self.delivery_contact_id ||= self.contact_id
    self.invoice_contact_id  ||= self.delivery_contact_id
    self.created_on ||= Date.today
    self.nature ||= self.company.sale_natures.first if self.nature.nil? and self.company.sale_natures.count == 1
    if self.nature
      self.expiration_id ||= self.nature.expiration_id 
      self.expired_on ||= self.expiration.compute(self.created_on)
      self.payment_delay_id ||= self.nature.payment_delay_id 
      self.has_downpayment = self.nature.downpayment if self.has_downpayment.nil?
      self.downpayment_amount ||= self.amount*self.nature.downpayment_rate if self.amount>=self.nature.downpayment_minimum
    end

    self.sum_method = 'wt'
    true
  end
  
  before_validation(:on=>:create) do
    self.created_on = Date.today
  end

  before_update do
    old = self.class.find(self.id)
    if old.invoice?
      for attr in self.class.columns_hash.keys - ["paid_amount"]
        self.send(attr+"=", old.send(attr))
      end
    end
  end


  # This method bookkeeps the sale depending on its state
  bookkeep do |b|
    label = tc(:bookkeep, :resource=>self.state_label, :number=>self.number, :client=>self.client.full_name, :products=>(self.comment.blank? ? self.lines.collect{|x| x.label}.to_sentence : self.comment), :sale=>self.initial_number)
    b.journal_entry(self.company.journal(:sales), :printed_on=>self.invoiced_on, :if=>self.invoice?) do |entry|
      entry.add_debit(label, self.client.account(:client).id, self.amount) unless self.amount.zero?
      for line in self.lines
        entry.add_credit(label, (line.account||line.product.sales_account).id, line.pretax_amount) unless line.pretax_amount.zero?
        entry.add_credit(label, line.price.tax.collected_account_id, line.taxes_amount) unless line.taxes_amount.zero?
      end
    end
    # self.uses.first.reconciliate if self.uses.first
  end


  def refresh
    self.save
  end

  def has_content?
    self.lines.size > 0
  end

  def has_content_deliverable?
    return false unless self.has_content?
    deliverable = false
    for line in self.lines
      deliverable = true if line.product.deliverable?
    end
    return deliverable
  end
  
  def has_content_not_deliverable?
    return false unless self.has_content?
    deliverable = false
    for line in self.lines
      deliverable = true if line.product.deliverable?
    end
    return !deliverable
  end


  # Remove all bad dependencies and return at draft state with no deliveries
  def correct(*args)
    return false unless self.can_correct?
    self.deliveries.clear
    return super
  end

  # Confirm the sale order. This permits to define deliveries and assert validity of sale
  def confirm(validated_on=Date.today, *args)
    return false unless self.can_confirm?
    self.reload.update_attributes!(:confirmed_on=>validated_on||Date.today)
    return super
  end
  

  # Create the last delivery with undelivered products if necessary.
  # The sale order is confirmed if it hasn't be done.
  def deliver
    return false unless self.order?
    lines = []
    for line in self.lines.find_all_by_reduction_origin_id(nil)
      quantity = line.undelivered_quantity
      if quantity > 0 and line.product.deliverable?
        lines << {:sale_line_id=>line.id, :quantity=>quantity, :company_id=>self.company_id}
      end
    end
    if lines.size>0
      delivery = self.deliveries.create!(:pretax_amount=>0, :amount=>0, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :contact_id=>self.delivery_contact_id)
      for line in lines
        delivery.lines.create! line
      end
      self.refresh
    end
    self
  end


  # Invoices all the products creating the delivery if necessary. 
  # Changes number with an invoice number saving exiting number in +initial_number+.
  def invoice(*args)
    return false unless self.can_invoice?
    self.confirm
    ActiveRecord::Base.transaction do
      # Set values for invoice
      self.invoiced_on = Date.today
      self.payment_on ||= self.payment_delay.compute if self.payment_delay      
      self.initial_number = self.number
      if sequence = self.company.preferred_sales_invoices_sequence
        self.number = sequence.next_value
      end
      self.save
      self.client.add_event(:sales_invoice, self.updater_id)
      return super
    end
    return false
  end

  # Delivers all undelivered products and sales invoice the order after. This operation cleans the order.
  def deliver_and_invoice
    self.deliver.invoice
  end

  # Duplicates a +sale+ in 'E' mode with its lines and its active subscriptions
  def duplicate(attributes={})
    fields = [:client_id, :nature_id, :currency_id, :letter_format, :annotation, :subject, :function_title, :introduction, :conclusion, :comment]
    hash = {}
    fields.each{|c| hash[c] = self.send(c)}
    copy = self.company.sales.build(attributes.merge(hash))
    copy.save!
    if copy.save
      # Lines
      lines = {}
      for line in self.lines.find(:all, :conditions=>["quantity>0"])
        l = copy.lines.create! :sale_id=>copy.id, :product_id=>line.product_id, :quantity=>line.quantity, :warehouse_id=>line.warehouse_id, :company_id=>self.company_id
        lines[line.id] = l.id
      end
      # Subscriptions
      for sub in self.subscriptions.find(:all, :conditions=>["NOT suspended"])
        copy.subscriptions.create!(:sale_id=>copy.id, :entity_id=>sub.entity_id, :contact_id=>sub.contact_id, :quantity=>sub.quantity, :nature_id=>sub.nature_id, :product_id=>sub.product_id, :company_id=>self.company_id, :sale_line_id=>lines[sub.sale_line_id])
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
    array = []
    array << [:client_balance, self.client.balance] if options[:with_balance]
    array << [:total_amount, self.amount]
    array << [:paid_amount, self.paid_amount]
    array << [:unpaid_amount, self.unpaid_amount]
    array 
  end


  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end


  # Obsolete
  def text_state
    puts "DEPRECATION WARNING: Please use state_label in place of text_state"
    state_label
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end
  
  # Prints human name of current state
  def state_label
    self.class.state_label(self.state)
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:pretax_amount+
  def undelivered(column)
    sum  = self.send(column)
    sum -= self.deliveries.sum(column)
    sum.round(2)
  end


  # Returns true if there is some undelivered deliverable products
  def deliverable?
    self.has_content_deliverable? and not self.undelivered(:amount).zero? and (self.invoice? or self.order?)
  end

  # Calculate unpaid amount
  def unpaid_amount
    self.amount - self.paid_amount
  end

  # Label of the sales order depending on the state and the number
  def label
    tc('label.'+self.state, :number=>self.number)
  end

  # Alias for letter_format? method
  def letter?
    self.letter_format?
  end

  def tags
    if self.order? or self.invoice? and !self.credit? and !self.amount.zero?
      if self.paid_amount.zero?
        return "critic "+self.state
      elsif self.paid_amount != self.amount
        return "warning "+self.state
      else
        return self.state
      end
    elsif self.credit?
      return "disabled "+self.state      
    end
    return self.state
  end

  def address
    a = self.client.full_name+"\n"
    c = (self.invoice? ? self.invoice_contact : self.contact)
    a += (c ? c.address : self.client.default_contact.address).gsub(/\s*\,\s*/, "\n")
    a
  end

  def number_label
    tc("number_label."+(self.estimate? ? 'proposal' : 'command'), :number=>self.number)
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  def usable_payments
    self.company.incoming_payments.find(:all, :conditions=>["COALESCE(paid_amount, 0)<COALESCE(amount, 0)"], :order=>"amount")
  end

  # Build general sales condition for the sale order
  def sales_conditions
    c = []
    c << tc('sales_conditions.downpayment', :percent=>100*self.nature.downpayment_rate, :amount=>(self.nature.downpayment_rate*self.amount).round(2)) if self.amount>self.nature.downpayment_minimum
    c << tc('sales_conditions.validity', :expiration=>::I18n.localize(self.expired_on, :format=>:legal))
    c += self.company.sales_conditions.to_s.split(/\s*\n\s*/)
    c += self.responsible.department.sales_conditions.to_s.split(/\s*\n\s*/) if self.responsible and self.responsible.department
    c
  end

  def unpaid_days
    (Date.today - self.invoiced_on) if self.invoice?
  end

  def products
    p = []
    for line in self.lines
      p << line.product.name
    end
    ps = p.join(", ")
  end

  # Returns true if sale is cancelable as an invoice
  def cancelable?
    not self.credit? and self.invoice? and self.lines.sum(:quantity) + self.credits.collect{|c| c.lines.sum(:quantity)}.sum > 0
  end

  # Create a credit for the selected invoice? guarding the reference
  def cancel(lines={}, options={})
    lines = lines.delete_if{|k,v| v.zero?}
    return false if !self.cancelable? or lines.size.zero?
    credit = self.class.new(:origin_id=>self.id, :client_id=>self.client_id, :credit=>true, :company_id=>self.company_id, :responsible=>options[:responsible]||self.responsible, :nature_id=>self.nature_id)
    ActiveRecord::Base.transaction do
      if saved = credit.save
        for line in self.lines.find(:all, :conditions=>{:id=>lines.keys})
          quantity = -lines[line.id.to_s].abs
          credit_line = credit.lines.create(:quantity=>quantity, :origin_id=>line.id, :product_id=>line.product_id, :price_id=>line.price_id, :company_id=>line.company_id, :reduction_percent=>line.reduction_percent)
          unless credit_line.save
            saved = false
            credit.errors.add_from_record(credit_line)
          end
        end
      else
        raise credit.errors.full_messages.inspect
      end
      if saved
        credit.reload
        credit.propose!
        # TODO: Manage returning deliveries because of the partial/total cancel
        credit.confirm!
        credit.invoice!
        self.reload.save
      else
        raise ActiveRecord::Rollback
      end
    end
    return credit
  end

end


