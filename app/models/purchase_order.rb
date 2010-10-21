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
# == Table: purchase_orders
#
#  accounted_at        :datetime         
#  amount              :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes   :decimal(16, 2)   default(0.0), not null
#  comment             :text             
#  company_id          :integer          not null
#  confirmed_on        :date             
#  created_at          :datetime         not null
#  created_on          :date             
#  creator_id          :integer          
#  currency_id         :integer          
#  delivery_contact_id :integer          
#  id                  :integer          not null, primary key
#  journal_entry_id    :integer          
#  lock_version        :integer          default(0), not null
#  moved_on            :date             
#  number              :string(64)       not null
#  paid_amount         :decimal(16, 2)   default(0.0), not null
#  planned_on          :date             
#  reference_number    :string(255)      
#  responsible_id      :integer          
#  state               :string(64)       
#  supplier_id         :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#

class PurchaseOrder < ActiveRecord::Base
  acts_as_accountable
  after_create {|r| r.supplier.add_event(:purchase_order, r.updater_id)}
  attr_readonly :company_id
  belongs_to :company
  belongs_to :currency
  belongs_to :delivery_contact, :class_name=>Contact.name
  belongs_to :journal_entry
  belongs_to :payee, :class_name=>Entity.name, :foreign_key=>:supplier_id
  belongs_to :supplier, :class_name=>Entity.name
  belongs_to :responsible, :class_name=>User.name
  has_many :lines, :class_name=>PurchaseOrderLine.name, :foreign_key=>:order_id
  has_many :deliveries, :class_name=>IncomingDelivery.name
  has_many :payment_uses, :foreign_key=>:expense_id, :class_name=>OutgoingPaymentUse.name, :dependent=>:destroy
  has_many :products, :through=>:lines, :uniq=>true

  validates_presence_of :planned_on, :created_on, :currency, :state
  validates_uniqueness_of :number, :scope=>:company_id

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
      transition [:ready, :refused, :processing] => :draft
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

  ## shipped used as received

  def prepare
    self.created_on ||= Date.today
    self.paid_amount = self.payment_uses.sum(:amount)||0
    if self.number.blank?
      #last = self.supplier.purchase_orders.find(:first, :order=>"number desc")
      last = self.company.purchase_orders.find(:first, :order=>"number desc")
      self.number = (last ? last.number.succ! : '00000001')
    end
    self.currency ||= self.company.default_currency

    self.amount = self.lines.sum(:amount)
    self.amount_with_taxes = self.lines.sum(:amount_with_taxes)
    return true
  end
  
  def clean_on_create
    specific_numeration = self.company.preference("management.purchase_orders.numeration").value
    self.number = specific_numeration.next_value unless specific_numeration.nil?
    return true
  end

  def refresh
    self.save
  end

  def has_content?
    self.lines.size > 0
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:amount_with_taxes+
  def undelivered(column)
    sum  = self.send(column)
    sum -= self.deliveries.sum(column)
    sum.round(2)
  end

  def deliverable?
    self.undelivered(:amount_with_taxes) > 0 and not self.invoiced?
  end
  

  def confirm(confirmed_on=Date.today, *args)
    return false unless self.can_confirm?
    self.confirmed_on = confirmed_on
    self.save
    return super
  end



  # Confirm the purchase by moving virtual and real stocks et closing
  # Move to accountancy if automatic
  def confirm2(finished_on=Date.today)
    self.shipped = true
    self.moved_on = finished_on
    if self.save
      for line in self.lines
        line.product.reserve_incoming_stock(:origin=>line)
        line.product.move_incoming_stock(:origin=>line)
      end
    end
  end

  def label 
    tc('label', :supplier=>self.supplier.full_name.to_s, :address=>self.dest_contact.address.to_s)
  end

  # Need for use in kame
  def quantity 
    ''
  end

  def destroyable?
    self.updatable?
  end

  def updatable?
    # return false if self.unpaid_amount.zero? and self.shipped
    return true
  end

  def last_payment
    self.company.payments.find(:first, :conditions=>{:entity_id=>self.company.entity_id}, :order=>"paid_on desc")
  end

  # Prints human name of current state
  def state_label
    tc('states.'+self.state.to_s)
  end

  def unpaid_amount(all=true)
    self.amount_with_taxes - self.paid_amount
  end

  def payment_entity_id
    self.company.entity.id
  end

  def usable_payments
    self.company.payments.find(:all, :conditions=>["COALESCE(paid_amount,0)<COALESCE(amount,0)"], :order=>"amount")
  end

  def status
    status = ""
    status = "critic" if self.paid_amount < self.amount_with_taxes
    status
  end

  def supplier_address
    a = self.supplier.full_name+"\n"
    a += (self.supplier.default_contact.address).gsub(/\s*\,\s*/, "\n") if self.supplier.default_contact
    a
  end

  def client_address
    a = self.company.entity.full_name+"\n"
    a += (self.dest_contact.address).gsub(/\s*\,\s*/, "\n") if self.dest_contact
    a
  end

  def taxes
    self.amount_with_taxes - self.amount
  end



  # Produces some amounts about the purchase order.
  def stats(options={})
    array = []
    array << [:total_amount, self.amount_with_taxes]
    array << [:paid_amount, self.paid_amount]
    array << [:unpaid_amount, self.unpaid_amount]
    array 
  end



  # This method permits to add journal entries corresponding to the purchase order/sales_invoice
  # It depends on the preference which permit to activate the "automatic accountizing"
  def to_accountancy(action=:create, options={})
    # accountize(action, {:journal=>self.company.journal(:purchases), :draft_mode=>options[:draft]}, :unless=>(self.lines.size.zero? or !self.shipped?)) do |entry|
    accountize(action, {:journal=>self.company.journal(:purchases), :draft_mode=>options[:draft]}, :if=>(self.invoiced? or self.finished?)) do |entry|
      label = tc(:to_accountancy, :resource=>self.class.human_name, :number=>self.number, :supplier=>self.supplier.full_name, :products=>(self.comment.blank? ? self.products.collect{|x| x.name}.to_sentence : self.comment))
      for line in self.lines
        entry.add_debit(label, line.product.purchases_account_id, line.amount) unless line.quantity.zero?
        entry.add_debit(label, line.price.tax.paid_account_id, line.taxes) unless line.taxes.zero?
      end
      entry.add_credit(label, self.supplier.account(:supplier).id, self.amount_with_taxes)
    end
  end

  
end
