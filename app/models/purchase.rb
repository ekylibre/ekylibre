# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: purchases
#
#  accounted_at                             :datetime
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  confirmed_at                             :datetime
#  contract_id                              :integer
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  id                                       :integer          not null, primary key
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  payment_at                               :datetime
#  payment_delay                            :string
#  planned_at                               :datetime
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  supplier_id                              :integer          not null
#  tax_payability                           :string           not null
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#

class Purchase < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency, :nature_id
  enumerize :tax_payability, in: %i[at_paying at_invoicing], default: :at_invoicing
  refers_to :currency
  belongs_to :delivery_address, class_name: 'EntityAddress'
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :undelivered_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :quantity_gap_on_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :nature, class_name: 'PurchaseNature'
  belongs_to :payee, class_name: 'Entity', foreign_key: :supplier_id
  belongs_to :supplier, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  belongs_to :contract
  has_many :parcels
  has_many :items, class_name: 'PurchaseItem', dependent: :destroy, inverse_of: :purchase
  has_many :journal_entries, as: :resource
  has_many :products, -> { uniq }, through: :items
  has_many :fixed_assets, through: :items
  has_one :supplier_payment_mode, through: :supplier
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :confirmed_at, :invoiced_at, :payment_at, :planned_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, :payee, :supplier, :tax_payability, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :state, presence: true, length: { maximum: 500 }
  validates :payment_delay, :reference_number, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :number, :state, length: { allow_nil: true, maximum: 60 }
  validates :created_at, :state, :nature, presence: true
  validates :number, uniqueness: true
  validates_associated :items
  validates_delay_format_of :payment_delay

  acts_as_numbered
  acts_as_affairable :supplier
  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:variant_id].blank? && item[:variant].blank? }, allow_destroy: true

  delegate :with_accounting, to: :nature
  delegate :third_attribute, to: :class

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :with_nature, ->(id) { where(nature_id: id) }

  scope :unpaid, -> { where(state: %w[order invoice]).where.not(affair: Affair.closeds) }
  scope :current, -> { unpaid }
  scope :current_or_self, ->(purchase) { where(unpaid).or(where(id: (purchase.is_a?(Purchase) ? purchase.id : purchase))) }
  scope :of_supplier, ->(supplier) { where(supplier_id: (supplier.is_a?(Entity) ? supplier.id : supplier)) }

  state_machine :state, initial: :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted
    event :propose do
      transition draft: :estimate, if: :has_content?
    end
    event :correct do
      transition %i[estimate refused order] => :draft
    end
    event :refuse do
      transition estimate: :refused, if: :has_content?
    end
    event :confirm do
      transition estimate: :order, if: :has_content?
    end
    event :invoice do
      transition order: :invoice, if: :has_content?
      transition estimate: :invoice, if: :has_content_not_deliverable?
      transition draft: :invoice
    end
    event :abort do
      transition %i[draft estimate] => :aborted # , :order
    end
  end

  before_validation(on: :create) do
    self.state = :draft
    self.currency ||= nature.currency if nature
  end

  before_validation do
    self.state ||= :draft
    self.created_at ||= Time.zone.now
    self.planned_at ||= self.created_at
    if payment_delay.blank? && supplier && supplier.supplier_payment_delay
      self.payment_delay = supplier.supplier_payment_delay
    end
    self.payment_at = if payment_delay.blank?
                        invoiced_at || self.planned_at
                      else
                        Delay.new(payment_delay).compute(invoiced_at || self.planned_at)
                      end
    self.pretax_amount = items.sum(:pretax_amount)
    self.amount = items.sum(:amount)
  end

  validate do
    if invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.zone.now.l) if invoiced_at > Time.zone.now
    end
  end

  after_update do
    affair.update_attributes(third_id: third.id) if affair && affair.deals.count == 1
    affair.reload_gaps if affair
    true
  end

  after_create do
    supplier.add_event(:purchase_creation, updater.person) if updater
  end

  after_save do
    items.each(&:update_fixed_asset) if invoice?
  end

  # This callback permits to add journal entries corresponding to the purchase order/invoice
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    b.journal_entry(nature.journal, printed_on: invoiced_on, if: (with_accounting && invoice? && items.any?)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, number: number, supplier: supplier.full_name, products: (description.blank? ? items.collect(&:name).to_sentence : description))
      items.each do |item|
        entry.add_debit(label, item.account, item.pretax_amount, activity_budget: item.activity_budget, team: item.team, as: :item_product, resource: item, variant: item.variant)
        tax = item.tax
        account_id = item.fixed? ? tax.fixed_asset_deduction_account_id : nil
        account_id ||= tax.deduction_account_id # TODO: Check if it is good to do that
        if tax.intracommunity
          reverse_charge_amount = tax.compute(item.pretax_amount, intracommunity: true).round(precision)
          entry.add_debit(label, account_id, reverse_charge_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant)
          entry.add_credit(label, tax.intracommunity_payable_account_id, reverse_charge_amount, tax: tax, pretax_amount: item.pretax_amount, resource: item, as: :item_tax_reverse_charge, variant: item.variant)
        else
          entry.add_debit(label, account_id, item.taxes_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant)
        end
      end
      entry.add_credit(label, supplier.account(nature.payslip? ? :employee : :supplier).id, amount, as: :supplier)
    end

    # For undelivered invoice
    # exchange undelivered invoice from parcel
    journal = unsuppress { Journal.used_for_unbilled_payables!(currency: currency) }
    b.journal_entry(journal, printed_on: invoiced_on, as: :undelivered_invoice, if: (with_accounting && invoice?)) do |entry|
      parcels.each do |parcel|
        next unless parcel.undelivered_invoice_journal_entry
        label = tc(:exchange_undelivered_invoice, resource: parcel.class.model_name.human, number: parcel.number, entity: supplier.full_name, mode: parcel.nature.l)
        undelivered_items = parcel.undelivered_invoice_journal_entry.items
        undelivered_items.each do |undelivered_item|
          next unless undelivered_item.real_balance.nonzero?
          entry.add_credit(label, undelivered_item.account.id, undelivered_item.real_balance, resource: undelivered_item, as: :undelivered_item, variant: undelivered_item.variant)
        end
      end
    end

    # For gap between parcel item quantity and purchase item quantity
    # if more quantity on purchase than parcel then i have value in D of stock account
    journal = unsuppress { Journal.used_for_permanent_stock_inventory!(currency: currency) }
    b.journal_entry(journal, printed_on: invoiced_on, as: :quantity_gap_on_invoice, if: (with_accounting && invoice? && items.any?)) do |entry|
      label = tc(:quantity_gap_on_invoice, resource: self.class.model_name.human, number: number, entity: supplier.full_name)
      items.each do |item|
        next unless item.variant.storable?
        parcel_items_quantity = item.parcel_items.map(&:population).compact.sum
        gap = item.quantity - parcel_items_quantity
        next unless item.parcel_items.any? && item.parcel_items.first.unit_pretax_stock_amount
        quantity = item.parcel_items.first.unit_pretax_stock_amount
        gap_value = gap * quantity
        next if gap_value.zero?
        entry.add_debit(label, item.variant.stock_account_id, gap_value, resource: item, as: :stock, variant: item.variant)
        entry.add_credit(label, item.variant.stock_movement_account_id, gap_value, resource: item, as: :stock_movement, variant: item.variant)
      end
    end
  end

  def self.third_attribute
    :supplier
  end

  def self.affair_class
    "#{name}Affair".constantize
  end

  def third
    send(third_attribute)
  end

  def default_currency
    currency || nature.currency
  end

  def precision
    Nomen::Currency.find(currency).precision
  end

  def invoiced_on
    dealt_at.to_date
  end

  def dealt_at
    (invoice? ? invoiced_at : created_at? ? self.created_at : Time.zone.now)
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(mode = :debit)
    return [] if deal_mode_amount(mode).zero?
    taxes = {}
    coeff = 1.to_d # (self.send("deal_#{mode}?") ? 1 : -1)
    for item in items
      taxes[item.tax_id] ||= { amount: 0.0.to_d, tax: item.tax }
      taxes[item.tax_id][:amount] += coeff * item.amount
    end
    taxes.values
  end

  def refresh
    save
  end

  def has_content?
    items.any?
  end

  def purchased?
    (order? || invoice?)
  end

  def has_content_not_deliverable?
    return false unless has_content?
    deliverable = false
    for item in items
      deliverable = true if item.variant.deliverable?
    end
    !deliverable
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:pretax_amount+
  def undelivered(column)
    sum  = send(column)
    sum -= parcels.sum(column)
    sum.round(2)
  end

  def deliverable?
    # TODO: How to compute if it remains deliverable products
    true
    # (self.quantity - self.undelivered(:population)) > 0 and not self.invoice?
  end

  # Save the last date when the purchase was confirmed
  def confirm(confirmed_at = nil)
    return false unless can_confirm?
    reload
    self.confirmed_at ||= confirmed_at || Time.zone.now
    save!
    super
  end

  # Save the last date when the invoice of purchase was received
  def invoice(invoiced_at = nil)
    return false unless can_invoice?
    reload
    self.invoiced_at ||= invoiced_at || Time.zone.now
    save!
    super
  end

  def label
    number # tc('label', :supplier => self.supplier.full_name.to_s, :address => self.delivery_address.mail_coordinate.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(state.to_sym).human_name
  end

  def status
    return affair.status if invoice?
    :stop
  end

  def supplier_address
    if supplier.default_mail_address
      return supplier.default_mail_address.mail_coordinate
    end
    nil
  end

  def client_address
    Entity.of_company.default_mail_address.mail_coordinate
  end

  def taxes_amount
    amount - pretax_amount
  end

  def can_generate_parcel?
    items.any? && delivery_address && (order? || invoice?)
  end

  def payable?
    (order? || invoice?) && sepable? && amount != 0.0 && affair_balance != 0.0
  end

  def sepable?
    cash_mode = OutgoingPaymentMode.mode_sepa.first

    cash_mode &&
      currency == cash_mode.cash.currency &&
      payee.iban.present? &&
      payee.bank_account_holder_name.present?
  end
end
