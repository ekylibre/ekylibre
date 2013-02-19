# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: purchases
#
#  accounted_at        :datetime
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  confirmed_on        :date
#  created_at          :datetime         not null
#  created_on          :date
#  creator_id          :integer
#  currency            :string(3)
#  delivery_address_id :integer
#  description         :text
#  id                  :integer          not null, primary key
#  invoiced_on         :date
#  journal_entry_id    :integer
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string(64)       not null
#  planned_on          :date
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string(255)
#  responsible_id      :integer
#  state               :string(64)
#  supplier_id         :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class Purchase < Ekylibre::Record::Base
  attr_accessible :description, :delivery_address_id, :nature_id, :planned_on, :reference_number, :responsible_id, :supplier_id
  attr_readonly :currency
  belongs_to :delivery_address, :class_name => "EntityAddress"
  belongs_to :journal_entry
  belongs_to :nature, :class_name => "PurchaseNature"
  belongs_to :payee, :class_name => "Entity", :foreign_key => :supplier_id
  belongs_to :supplier, :class_name => "Entity"
  belongs_to :responsible, :class_name => "Entity"
  has_many :items, :class_name => "PurchaseItem", :foreign_key => :purchase_id
  has_many :deliveries, :class_name => "IncomingDelivery"
  has_many :products, :through => :items, :uniq => true
  #[VALIDATORS[ Do not edit these items directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :number, :state, :allow_nil => true, :maximum => 64
  validates_length_of :reference_number, :allow_nil => true, :maximum => 255
  validates_presence_of :amount, :number, :payee, :pretax_amount, :supplier
  #]VALIDATORS]
  validates_presence_of :planned_on, :created_on, :currency, :state, :nature
  validates_uniqueness_of :number

  acts_as_numbered
  acts_as_affairable :third => :supplier
  after_create {|r| r.supplier.add_event(:purchase, r.updater_id)}
  state_machine :state, :initial => :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted
    event :propose do
      transition :draft => :estimate, :if => :has_content?
    end
    event :correct do
      transition [:estimate, :refused, :order] => :draft
    end
    event :refuse do
      transition :estimate => :refused, :if => :has_content?
    end
    event :confirm do
      transition :estimate => :order, :if => :has_content?
    end
    event :invoice do
      transition :order => :invoice, :if => :has_content?
      transition :estimate => :invoice, :if => :has_content_not_deliverable?
    end
    event :abort do
      transition [:draft, :estimate] => :aborted # , :order
    end
  end

  before_validation(:on => :create) do
    self.currency = self.nature.currency if self.nature
  end

  before_validation do
    self.created_on ||= Date.today
    self.paid_amount = self.payment_uses.sum(:amount)||0
    if eoc = Entity.of_company
      self.currency ||= eoc.currency
    end
    self.pretax_amount = self.items.sum(:pretax_amount)
    self.amount = self.items.sum(:amount)
    return true
  end

  protect(:on => :destroy) do
    self.updateable?
  end

  protect(:on => :update) do
    # return false if self.unpaid_amount.zero? and self.shipped
    return true
  end

  # This method permits to add journal entries corresponding to the purchase order/invoice
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    b.journal_entry(self.nature.journal, :if => self.invoice?) do |entry|
      label = tc(:bookkeep, :resource => self.class.model_name.human, :number => self.number, :supplier => self.supplier.full_name, :products => (self.description.blank? ? self.products.collect{|x| x.name}.to_sentence : self.description))
      for item in self.items
        entry.add_debit(label, item.product.purchases_account_id, item.pretax_amount) unless item.quantity.zero?
        entry.add_debit(label, item.price.tax.paid_account_id, item.taxes_amount) unless item.taxes_amount.zero?
      end
      entry.add_credit(label, self.supplier.account(:supplier).id, self.amount)
    end
#     if use = self.uses.first
#       use.reconciliate
#     end
  end

  def dealt_on
    return (self.invoice? ? self.invoiced_on : self.created_on)
  end

  def refresh
    self.save
  end

  def has_content?
    self.items.count > 0
  end

  def purchased?
    return (self.order? or self.invoice?)
  end

  def has_content_not_deliverable?
    return false unless self.has_content?
    deliverable = false
    for item in self.items
      deliverable = true if item.product.deliverable?
    end
    return !deliverable
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:pretax_amount+
  def undelivered(column)
    sum  = self.send(column)
    sum -= self.deliveries.sum(column)
    sum.round(2)
  end

  def deliverable?
    self.undelivered(:amount) > 0 and not self.invoice?
  end

  # Save the last date when the purchase was confirmed
  def confirm(validated_on=Date.today, *args)
    return false unless self.can_confirm?
    self.reload.update_attributes!(:confirmed_on => validated_on||Date.today)
    return super
  end

  # Save the last date when the invoice of purchase was received
  def invoice(invoiced_on=nil, *args)
    return false unless self.can_invoice?
    invoiced_on ||= self.planned_on
    self.reload.update_attributes!(:invoiced_on => invoiced_on)
    return super
  end

  def label
    self.number# tc('label', :supplier => self.supplier.full_name.to_s, :address => self.delivery_address.mail_coordinate.to_s)
  end

  # Need for use in list
  def quantity
    ''
  end

  # Prints human name of current state
  def state_label
    tc('states.'+self.state.to_s)
  end

  def unpaid_amount
    self.amount - self.paid_amount
  end

  def status
    status = ""
    status = "critic" if self.paid_amount < self.amount
    status
  end

  def supplier_address
    return self.supplier.default_mail_address.mail_coordinate
  end

  def client_address
    return Entity.of_company.default_mail_address.mail_coordinate
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  # Produces some amounts about the purchase order.
  def stats(options={})
    array = []
    array << [:amount, self.amount]
    array << [:paid_amount, self.paid_amount]
    array << [:unpaid_amount, self.unpaid_amount]
    array
  end

end
