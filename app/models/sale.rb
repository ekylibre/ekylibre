# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: sales
#
#  accounted_at        :datetime
#  address_id          :integer
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  annotation          :text
#  client_id           :integer          not null
#  computation_method  :string           not null
#  conclusion          :text
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  creator_id          :integer
#  credit              :boolean          default(FALSE), not null
#  credited_sale_id    :integer
#  currency            :string           not null
#  delivery_address_id :integer
#  description         :text
#  downpayment_amount  :decimal(19, 4)   default(0.0), not null
#  expiration_delay    :string
#  expired_at          :datetime
#  function_title      :string
#  has_downpayment     :boolean          default(FALSE), not null
#  id                  :integer          not null, primary key
#  initial_number      :string
#  introduction        :text
#  invoice_address_id  :integer
#  invoiced_at         :datetime
#  journal_entry_id    :integer
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string           not null
#  payment_at          :datetime
#  payment_delay       :string           not null
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string
#  responsible_id      :integer
#  state               :string           not null
#  subject             :string
#  transporter_id      :integer
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class Sale < Ekylibre::Record::Base
  enumerize :computation_method, in: [:adaptative, :quantity_tax, :tax_quantity], default: :adaptative, predicates: {prefix: true}
  attr_readonly :currency
  belongs_to :affair
  belongs_to :client, class_name: "Entity"
  belongs_to :payer, class_name: "Entity", foreign_key: :client_id
  belongs_to :address, class_name: "EntityAddress"
  belongs_to :delivery_address, class_name: "EntityAddress"
  belongs_to :invoice_address, class_name: "EntityAddress"
  belongs_to :journal_entry
  belongs_to :nature, class_name: "SaleNature"
  belongs_to :credited_sale, class_name: "Sale"
  belongs_to :responsible, class_name: "Person"
  belongs_to :transporter, class_name: "Entity"
  has_many :credits, class_name: "Sale", foreign_key: :credited_sale_id
  has_many :deliveries, class_name: "OutgoingDelivery", dependent: :destroy, inverse_of: :sale
  has_many :documents, :as => :owner
  has_many :items, -> { order("position, id") }, class_name: "SaleItem", dependent: :destroy, inverse_of: :sale
  has_many :journal_entries, :as => :resource
  has_many :subscriptions, class_name: "Subscription"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :accounted_at, :confirmed_at, :expired_at, :invoiced_at, :payment_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :amount, :downpayment_amount, :pretax_amount, allow_nil: true
  validates_inclusion_of :credit, :has_downpayment, :letter_format, in: [true, false]
  validates_presence_of :amount, :client, :computation_method, :currency, :downpayment_amount, :number, :payer, :payment_delay, :pretax_amount, :state
  #]VALIDATORS]
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :initial_number, :number, :state, allow_nil: true, maximum: 60
  validates_presence_of :client, :currency, :nature
  validates_presence_of :invoiced_at, if: :invoice?
  validates_delay_format_of :payment_delay, :expiration_delay

  acts_as_numbered :number, readonly: false
  acts_as_affairable :client, debit: :credit?
  accepts_nested_attributes_for :items, :reject_if => :all_blank, :allow_destroy => true

  delegate :closed, to: :affair, prefix: true

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :estimate_between, lambda { |started_at, stopped_at|
    where(accounted_at: started_at..stopped_at, state: :estimate)
  }

  scope :unpaid, -> { where(state: ["order", "invoice"]).where("payment_at IS NULL OR payment_at <= ?", Time.now).where.not(affair: Affair.closeds) }

  state_machine :state, :initial => :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted

    event :propose do
      transition :draft => :estimate, if: :has_content?
    end
    event :correct do
      transition :estimate => :draft
      transition :refused => :draft
      transition :order => :draft, if: lambda{|sale| !sale.partially_closed?}
    end
    event :refuse do
      transition :estimate => :refused, if: :has_content?
    end
    event :confirm do
      transition :estimate => :order, if: :has_content?
    end
    event :invoice do
      transition :order => :invoice, if: :has_content?
      transition :estimate => :invoice, if: :has_content?
    end
    event :abort do
      transition :draft => :aborted
    end
  end

  before_validation(on: :create) do
    self.state ||= :draft
    self.currency = self.nature.currency if self.nature
    self.created_at = Time.now
  end

  before_validation do
    if self.address.nil? and self.client
      dc = self.client.default_mail_address
      self.address_id = dc.id if dc
    end
    self.delivery_address_id ||= self.address_id
    self.invoice_address_id  ||= self.delivery_address_id
    self.created_at ||= Time.now
    self.nature ||= SaleNature.by_default if self.nature.nil?
    if self.nature
      self.expiration_delay ||= self.nature.expiration_delay
      self.expired_at ||= Delay.new(self.expiration_delay).compute(self.created_at)
      self.payment_delay ||= self.nature.payment_delay
      self.has_downpayment = self.nature.downpayment if self.has_downpayment.nil?
      self.downpayment_amount ||= (self.amount * self.nature.downpayment_percentage * 0.01) if self.amount >= self.nature.downpayment_minimum
      self.currency ||= self.nature.currency
    end
    true
  end

  validate do
    if self.invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.now.l) if self.invoiced_at > Time.now
    end
    for mail_address in [:address, :delivery_address, :invoice_address]
      if self.send(mail_address)
        unless self.send(mail_address).mail?
          errors.add(mail_address, :must_be_a_mail_address)
        end
      end
    end
  end

  before_update do
    old = self.class.find(self.id)
    if old.invoice?
      for attr in self.class.columns_definition.keys
        self.send(attr + "=", old.send(attr))
      end
    end
  end

  after_create do
    self.client.add_event(:sale_creation, self.updater.person) if self.updater and self.updater.person
  end

  # This callback bookkeeps the sale depending on its state
  bookkeep do |b|
    b.journal_entry(self.nature.journal, printed_on: self.invoiced_on, if: (self.nature.with_accounting? and self.invoice?)) do |entry|
      label = tc(:bookkeep, :resource => self.state_label, :number => self.number, :client => self.client.full_name, :products => (self.description.blank? ? self.items.pluck(:label).to_sentence : self.description), :sale => self.initial_number)
      entry.add_debit(label, self.client.account(:client).id, self.amount) unless self.amount.zero?
      for item in self.items
        entry.add_credit(label, (item.account||item.variant.product_account).id, item.pretax_amount) unless item.pretax_amount.zero?
        entry.add_credit(label, item.tax.collect_account_id, item.taxes_amount) unless item.taxes_amount.zero?
      end
    end
  end

  def invoiced_on
    return dealt_at.to_date
  end

  # Gives the date to use for affair bookkeeping
  def dealt_at
    return (self.invoice? ? self.invoiced_at : self.created_at)
  end

  # Gives the amount to use for affair bookkeeping
  def deal_amount
    return ((self.aborted? or self.refused?) ? 0 : self.credit? ? -self.amount : self.amount)
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(mode = :debit)
    return [] if self.deal_mode_amount(mode).zero?
    taxes = {}
    coeff = (self.credit? ? -1 : 1).to_d
    # coeff *= (self.send("deal_#{mode}?") ? 1 : -1)
    for item in self.items
      taxes[item.tax_id] ||= {amount: 0.0.to_d, tax: item.tax}
      taxes[item.tax_id][:amount] += coeff * item.amount
    end
    return taxes.values
  end

  def partially_closed?
    !self.affair.debit.zero? and !self.affair.credit.zero?
  end

  def supplier
    Entity.of_company
  end

  def client_number
    self.client.number
  end

  def nature=(value)
    super(value)
    self.currency = self.nature.currency if self.nature
  end

  # Save a new time
  def refresh
    self.save
  end

  # Test if there is some items in the sale.
  def has_content?
    self.items.any?
  end

  # Returns if the sale has been validated and so if it can be
  # considered as sold.
  def sold?
    return (self.order? or self.invoice?)
  end

  # Remove all bad dependencies and return at draft state with no deliveries
  def correct
    return false unless self.can_correct?
    self.deliveries.clear
    return super
  end

  # Confirm the sale order. This permits to define deliveries and assert validity of sale
  def confirm(confirmed_at = Time.now)
    return false unless self.can_confirm?
    self.update_column(:confirmed_at, confirmed_at || Time.now)
    return super
  end

  # Invoices all the products creating the delivery if necessary.
  # Changes number with an invoice number saving exiting number in +initial_number+.
  def invoice(invoiced_at = Time.now)
    return false unless self.can_invoice?
    ActiveRecord::Base.transaction do
      # Set values for invoice
      self.invoiced_at ||= invoiced_at
      self.payment_at ||= Delay.new(self.payment_delay).compute(self.invoiced_at)
      self.initial_number = self.number
      if sequence = Sequence.of(:sales_invoices)
        loop do
          self.number = sequence.next_value
          break unless self.class.find_by(number: self.number, state: "invoice")
        end
      end
      self.save!
      self.client.add_event(:sales_invoice_creation, self.updater.person) if self.updater
      return super
    end
    return false
  end

  # Duplicates a +sale+ in 'E' mode with its items and its active subscriptions
  def duplicate(attributes={})
    fields = [:client_id, :nature_id, :currency, :letter_format, :annotation, :subject, :function_title, :introduction, :conclusion, :description]
    hash = {}
    fields.each{|c| hash[c] = self.send(c)}
    copy = self.class.build(attributes.merge(hash))
    copy.save!
    if copy.save
      # Items
      items = {}
      for item in self.items.where("quantity > 0")
        l = copy.items.create! :sale_id => copy.id, :product_id => item.product_id, :quantity => item.quantity, :building_id => item.building_id
        items[item.id] = l.id
      end
      # Subscriptions
      for sub in self.subscriptions.where("NOT suspended")
        copy.subscriptions.create!(:sale_id => copy.id, :entity_id => sub.entity_id, :address_id => sub.address_id, :quantity => sub.quantity, :nature_id => sub.nature_id, :product_id => sub.product_id, :sale_item_id => items[sub.sale_item_id])
      end
    else
      raise StandardError.new(copy.errors.inspect)
    end
    copy
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(self.state.to_sym).human_name
  end

  # Returns true if there is some products to deliver
  def deliverable?
    # not self.undelivered(:quantity).zero? and (self.invoice? or self.order?)
    # !self.undelivered_items.count.zero? and (self.invoice? or self.order?)
    true
  end

  # Label of the sales order depending on the state and the number
  def name
    tc('label.' + self.state, :number => self.number)
  end
  alias :label :name

  # Alias for letter_format? method
  def letter?
    self.letter_format?
  end

  def mail_address
    return (self.address || self.client.default_mail_address).mail_coordinate
  end

  def number_label
    tc("number_label."+(self.estimate? ? 'proposal' : 'command'), :number => self.number)
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  def usable_payments
    self.client.incoming_payments.where("COALESCE(used_amount, 0)<COALESCE(amount, 0)").joins(:mode => :cash).where(currency: self.currency).order("to_bank_at")
  end

  def sales_mentions
    # get preference for sales conditions
    preference_sales_conditions = Preference.global.where(name: :sales_conditions).first
    if preference_sales_conditions
      return preference_sales_conditions.value
    else
      return nil
    end
  end

  # Build general sales condition for the sale order
  def sales_conditions
    c = []
    c << tc('sales_conditions.downpayment', :percentage => self.nature.downpayment_percentage, :amount => (self.nature.downpayment_percentage * 0.01 * self.amount).round(2)) if self.amount > self.nature.downpayment_minimum
    c << tc('sales_conditions.validity', :expiration => ::I18n.localize(self.expired_at, :format => :default))
    c += self.nature.sales_conditions.to_s.split(/\s*\n\s*/) if self.nature.sales_conditions
    c += self.responsible.team.sales_conditions.to_s.split(/\s*\n\s*/) if self.responsible and self.responsible.team
    c
  end

  def unpaid_days
    (Time.now - self.invoiced_at) if self.invoice?
  end

  def products
    p = []
    for item in self.items
      p << item.product.name
    end
    ps = p.join(", ")
  end

  # Returns true if sale is cancellable as an invoice
  def cancellable?
    not self.credit? and self.invoice? and self.amount + self.credits.sum(:amount) > 0
  end

  # Build a new sale with new items ready for correction and save
  def build_credit
    attrs = [:affair, :client, :address, :responsible, :nature, :computation_method, :currency, :invoice_address, :transporter].inject({}) do |hash, attribute|
      hash[attribute] = self.send(attribute) unless self.send(attribute).nil?
      hash
    end
    attrs[:invoiced_at] = Time.now
    attrs[:credit] = true
    attrs[:credited_sale] = self
    sale_credit = SaleCredit.new(attrs)
    self.items.each do |item|
      attrs = [:account, :currency, :variant, :unit_pretax_amount, :unit_amount, :reduction_percentage, :tax].inject({}) do |hash, attribute|
        hash[attribute] = item.send(attribute) unless item.send(attribute).nil?
        hash
      end
      attrs[:quantity] = (item.quantity + item.credited_quantity)
      attrs[:reference_value] = :quantity
      attrs[:credited_item] = item
      if attrs[:quantity] > 0
        item_credit = sale_credit.items.build(attrs)
        item_credit.compute_amounts
      end
    end
    # sale_credit.valid?
    return sale_credit
  end

  # Returns status of affair if invoiced else "stop"
  def status
    if self.invoice? and self.affair
      return self.affair.status
    end
    return :stop
  end

end


