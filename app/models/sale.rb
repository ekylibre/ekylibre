# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  accounted_at                             :datetime
#  address_id                               :integer
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  annotation                               :text
#  client_id                                :integer          not null
#  codes                                    :jsonb
#  conclusion                               :text
#  confirmed_at                             :datetime
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  credit                                   :boolean          default(FALSE), not null
#  credited_sale_id                         :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  downpayment_amount                       :decimal(19, 4)   default(0.0), not null
#  expiration_delay                         :string
#  expired_at                               :datetime
#  function_title                           :string
#  has_downpayment                          :boolean          default(FALSE), not null
#  id                                       :integer          not null, primary key
#  initial_number                           :string
#  introduction                             :text
#  invoice_address_id                       :integer
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  letter_format                            :boolean          default(TRUE), not null
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  payment_at                               :datetime
#  payment_delay                            :string           not null
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  subject                                  :string
#  transporter_id                           :integer
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
require 'benchmark'

class Sale < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency
  refers_to :currency
  belongs_to :affair
  belongs_to :client, class_name: 'Entity'
  belongs_to :payer, class_name: 'Entity', foreign_key: :client_id
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :delivery_address, class_name: 'EntityAddress'
  belongs_to :invoice_address, class_name: 'EntityAddress'
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :undelivered_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :quantity_gap_on_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :nature, class_name: 'SaleNature'
  belongs_to :credited_sale, class_name: 'Sale'
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  belongs_to :transporter, class_name: 'Entity'
  has_many :credits, class_name: 'Sale', foreign_key: :credited_sale_id
  has_many :parcels, dependent: :destroy, inverse_of: :sale, class_name: 'Shipment'
  has_many :items, -> { order('position, id') }, class_name: 'SaleItem', dependent: :destroy, inverse_of: :sale
  has_many :journal_entries, as: :resource
  has_many :subscriptions, through: :items, class_name: 'Subscription', source: 'subscription'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :confirmed_at, :expired_at, :invoiced_at, :payment_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :downpayment_amount, :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :annotation, :conclusion, :description, :introduction, length: { maximum: 500_000 }, allow_blank: true
  validates :credit, :has_downpayment, :letter_format, inclusion: { in: [true, false] }
  validates :client, :currency, :payer, presence: true
  validates :expiration_delay, :function_title, :initial_number, :reference_number, :subject, length: { maximum: 500 }, allow_blank: true
  validates :number, :payment_delay, :state, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :initial_number, :number, :state, length: { allow_nil: true, maximum: 60 }
  validates :client, :currency, :nature, presence: true
  validates :invoiced_at, presence: { if: :invoice? }
  validates_delay_format_of :payment_delay, :expiration_delay

  acts_as_numbered :number, readonly: false
  acts_as_affairable :client, debit: :credit?
  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:variant_id].blank? }, allow_destroy: true

  delegate :with_accounting, to: :nature

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :estimate_between, lambda { |started_at, stopped_at|
    where(accounted_at: started_at..stopped_at, state: :estimate)
  }

  scope :with_nature, ->(id) { where(nature_id: id) }

  scope :unpaid, -> { where(state: %w[order invoice]).where.not(affair: Affair.closeds) }

  state_machine :state, initial: :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted

    event :propose do
      transition draft: :estimate, if: :has_content?
      transition refused: :estimate
    end
    event :correct do
      transition estimate: :draft
      transition refused: :draft
      transition order: :draft # , if: lambda{|sale| !sale.partially_closed?}
    end
    event :refuse do
      transition estimate: :refused, if: :has_content?
    end
    event :confirm do
      transition estimate: :order, if: :has_content?
    end
    event :invoice do
      transition %i[draft estimate order] => :invoice, if: :has_content?
    end
    event :abort do
      transition draft: :aborted
      transition estimate: :aborted
    end
  end

  before_validation(on: :create) do
    self.state = :draft
    self.currency ||= nature.currency if nature
    self.created_at = Time.zone.now
  end

  before_validation do
    if address.nil? && client
      dc = client.default_mail_address
      self.address_id = dc.id if dc
    end
    self.delivery_address_id ||= address_id
    self.invoice_address_id ||= self.delivery_address_id
    self.created_at ||= Time.zone.now
    self.nature ||= SaleNature.by_default if nature.nil?
    if self.nature
      self.expiration_delay ||= self.nature.expiration_delay
      self.expired_at ||= Delay.new(self.expiration_delay).compute(self.created_at)
      self.payment_delay ||= self.nature.payment_delay
      self.has_downpayment = self.nature.downpayment if has_downpayment.nil?
      if amount >= self.nature.downpayment_minimum
        self.downpayment_amount ||= (amount * self.nature.downpayment_percentage * 0.01)
      end
      self.currency ||= self.nature.currency
    end
    true
  end

  validate do
    if invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.zone.now.l) if invoiced_at > Time.zone.now
    end
    %i[address delivery_address invoice_address].each do |mail_address|
      next unless send(mail_address)
      unless send(mail_address).mail?
        errors.add(mail_address, :must_be_a_mail_address)
      end
    end
  end

  before_update do
    if old_record.invoice?
      self.class.columns_definition.keys.each do |attr|
        send(attr + '=', old_record.send(attr))
      end
    end
  end

  after_create do
    client.add_event(:sale_creation, updater.person) if updater && updater.person
    true
  end

  protect on: :update do
    old_record.invoice?
  end

  protect on: :destroy do
    old_record.invoice? || old_record.order? || !parcels.all?(&:destroyable?) || !subscriptions.all?(&:destroyable?)
  end

  # This callback bookkeeps the sale depending on its state
  bookkeep do |b|
    b.journal_entry(self.nature.journal, printed_on: invoiced_on, if: (with_accounting && invoice? && items.any?)) do |entry|
      label = tc(:bookkeep, resource: state_label, number: number, client: client.full_name, products: (description.blank? ? items.pluck(:label).to_sentence : description), sale: initial_number)
      entry.add_debit(label, client.account(:client).id, amount, as: :client)

      for item in items
        item_variant = item.variant
        tax = item.tax

        entry.add_credit(label, (item.account || item_variant.product_account).id, item.pretax_amount, activity_budget: item.activity_budget, team: item.team, as: :item_product, resource: item, variant: item_variant)
        entry.add_credit(label, tax.collect_account_id, item.taxes_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item_variant)
      end
    end

    # For undelivered invoice
    # exchange undelivered invoice from parcel
    journal = unsuppress { Journal.used_for_unbilled_payables!(currency: self.currency) }
    b.journal_entry(journal, printed_on: invoiced_on, as: :undelivered_invoice, if: (with_accounting && invoice?)) do |entry|
      for parcel in parcels
        next unless parcel.undelivered_invoice_journal_entry
        label = tc(:exchange_undelivered_invoice, resource: parcel.class.model_name.human, number: parcel.number, entity: supplier.full_name, mode: parcel.nature.tl)
        undelivered_items = parcel.undelivered_invoice_journal_entry.items
        undelivered_items.each do |undelivered_item|
          next unless undelivered_item.real_balance.nonzero?
          entry.add_credit(label, undelivered_item.account.id, undelivered_item.real_balance, resource: undelivered_item, as: :item_product, variant: undelivered_item.variant)
        end
      end
    end

    # For gap between parcel item quantity and sale item quantity
    # if more quantity on sale than parcel then i have value in C of stock account
    journal = unsuppress { Journal.used_for_permanent_stock_inventory!(currency: self.currency) }
    b.journal_entry(journal, printed_on: invoiced_on, as: :quantity_gap_on_invoice, if: (with_accounting && invoice? && items.any?)) do |entry|
      label = tc(:quantity_gap_on_invoice, resource: self.class.model_name.human, number: number, entity: client.full_name)

      for item in items
        next unless item.variant && item.variant.storable?
        shipment_items_quantity = item.shipment_items.map(&:population).compact.sum
        gap = item.quantity - shipment_items_quantity
        next unless item.shipment_items.any? && item.shipment_items.first.unit_pretax_stock_amount
        quantity = item.shipment_items.first.unit_pretax_stock_amount
        gap_value = gap * quantity
        next if gap_value.zero?
        entry.add_credit(label, item.variant.stock_account_id, gap_value, resource: item, as: :stock, variant: item.variant)
        entry.add_debit(label, item.variant.stock_movement_account_id, gap_value, resource: item, as: :stock_movement, variant: item.variant)
      end
    end
  end

  def invoiced_on
    dealt_at.to_date
  end

  def self.third_attribute
    :client
  end

  def self.affair_class
    "#{name}Affair".constantize
  end

  def default_currency
    currency || nature.currency
  end

  def third
    send(third_attribute)
  end

  # Gives the date to use for affair bookkeeping
  def dealt_at
    (invoice? ? invoiced_at : self.created_at)
  end

  # Gives the amount to use for affair bookkeeping
  def deal_amount
    (aborted? || refused? ? 0 : credit? ? -amount : amount)
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(mode = :debit)
    return [] if deal_mode_amount(mode).zero?
    taxes = {}
    coeff = (credit? ? -1 : 1).to_d
    # coeff *= (self.send("deal_#{mode}?") ? 1 : -1)
    for item in items
      taxes[item.tax_id] ||= { amount: 0.0.to_d, tax: item.tax }
      taxes[item.tax_id][:amount] += coeff * item.amount
    end
    taxes.values
  end

  def partially_closed?
    !affair.debit.zero? && !affair.credit.zero?
  end

  def supplier
    Entity.of_company
  end

  delegate :number, to: :client, prefix: true
  delegate :third_attribute, to: :class

  def nature=(value)
    super(value)
    self.currency = self.nature.currency if self.nature
  end

  # Save a new time
  def refresh
    save
  end

  # Test if there is some items in the sale.
  def has_content?
    items.any?
  end

  # Returns if the sale has been validated and so if it can be
  # considered as sold.
  def sold?
    (order? || invoice?)
  end

  # Check if sale can generate parcel from all the items of the sale
  def can_generate_parcel?
    items.any? && delivery_address && (order? || invoice?)
  end

  # Return at draft state
  def correct
    return false unless can_correct?
    super
  end

  # Confirm the sale order. This permits to define parcels and assert validity of sale
  def confirm(confirmed_at = Time.zone.now)
    return false unless can_confirm?
    update_column(:confirmed_at, confirmed_at || Time.zone.now)
    super
  end

  # Invoices all the products creating the delivery if necessary.
  # Changes number with an invoice number saving exiting number in +initial_number+.
  def invoice(invoiced_at = Time.zone.now)
    return false unless can_invoice?
    ActiveRecord::Base.transaction do
      # Set values for invoice
      self.invoiced_at ||= invoiced_at
      self.confirmed_at ||= self.invoiced_at
      self.payment_at ||= Delay.new(self.payment_delay).compute(self.invoiced_at)
      self.initial_number = number

      if sequence = Sequence.of(:sales_invoices)
        loop do
          self.number = sequence.next_value!
          break unless self.class.find_by(number: number)
        end
      end

      save!

      client.add_event(:sales_invoice_creation, updater.person) if updater

      return super
    end
    false
  end

  def duplicatable?
    !credit
  end

  # Duplicates a +sale+ in estimate state with its items and its active
  # subscriptions
  def duplicate(attributes = {})
    raise StandardError, 'Uncancelable sale' unless duplicatable?
    hash = %i[
      client_id nature_id letter_format annotation subject
      function_title introduction conclusion description
    ].each_with_object({}) do |field, h|
      h[field] = send(field)
    end
    # Items
    items_attributes = {}
    items.order(:position).each_with_index do |item, index|
      attrs = %i[
        variant_id quantity amount label pretax_amount annotation
        reduction_percentage tax_id unit_amount unit_pretax_amount
      ].each_with_object({}) do |field, h|
        h[field] = item.send(field)
      end
      # Subscription
      subscription = item.subscription
      if subscription
        attrs[:subscription_attributes] = subscription.following_attributes
      end
      items_attributes[index.to_s] = attrs
    end
    hash[:items_attributes] = items_attributes
    self.class.create!(hash.with_indifferent_access.deep_merge(attributes))
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(state.to_sym).human_name
  end

  # Returns true if there is some products to deliver
  def deliverable?
    # not self.undelivered(:quantity).zero? and (self.invoice? or self.order?)
    # !self.undelivered_items.count.zero? and (self.invoice? or self.order?)
    true
  end

  # Label of the sales order depending on the state and the number
  def name
    tc("label.#{credit? && invoice? ? :credit : state}", number: number)
  end
  alias label name

  # Alias for letter_format? method
  def letter?
    letter_format?
  end

  def mail_address
    (address || client.default_mail_address).mail_coordinate
  end

  def number_label
    tc('number_label.' + (estimate? ? 'proposal' : 'command'), number: number)
  end

  def taxes_amount
    amount - pretax_amount
  end

  def sales_mentions
    # get preference for sales conditions
    preference_sales_conditions = Preference.global.find_by(name: :sales_conditions)
    if preference_sales_conditions
      return preference_sales_conditions.value
    else
      return nil
    end
  end

  # Build general sales condition for the sale order
  def sales_conditions
    c = []
    c << tc('sales_conditions.downpayment', percentage: self.nature.downpayment_percentage, amount: self.downpayment_amount.l(currency: self.currency)) if amount > self.nature.downpayment_minimum && has_downpayment
    c << tc('sales_conditions.validity', expiration: self.expired_at.l)
    c += self.nature.sales_conditions.to_s.split(/\s*\n\s*/) if self.nature.sales_conditions
    # c += self.responsible.team.sales_conditions.to_s.split(/\s*\n\s*/) if self.responsible and self.responsible.team
    c
  end

  def unpaid_days
    (Time.zone.now - self.invoiced_at) if invoice?
  end

  def products
    items.map { |item| item.product.name }.join(', ')
  end

  # Returns true if sale is cancellable as an invoice
  def cancellable?
    !credit? && invoice? && amount + credits.sum(:amount) > 0
  end

  def cancel!
    s = build_credit
    s.save!
    s.invoice!
  end

  # Build a new sale with new items ready for correction and save
  def build_credit
    attrs = %i[affair client address responsible nature
               currency invoice_address transporter].each_with_object({}) do |attribute, hash|
      hash[attribute] = send(attribute) unless send(attribute).nil?
      hash
    end
    attrs[:invoiced_at] = Time.zone.now
    attrs[:credit] = true
    attrs[:credited_sale] = self
    sale_credit = Sale.new(attrs)
    x = []
    items.each do |item|
      attrs = %i[account currency variant reduction_percentage tax
                 compute_from unit_pretax_amount unit_amount].each_with_object({}) do |attribute, hash|
        hash[attribute] = item.send(attribute) unless item.send(attribute).nil?
        hash
      end
      %i[pretax_amount amount].each do |v|
        attrs[v] = -1 * item.send(v)
      end
      attrs[:credited_quantity] = item.creditable_quantity
      attrs[:quantity] = -1 * item.creditable_quantity
      attrs[:credited_item] = item
      if attrs[:credited_quantity] > 0
        sale_credit_item = sale_credit.items.build(attrs)
        sale_credit_item.valid?
      end
    end
    sale_credit
  end

  # Returns status of affair if invoiced else "stop"
  def status
    return affair.status if invoice? && affair
    :stop
  end
end
