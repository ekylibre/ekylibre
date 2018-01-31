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
# == Table: sale_items
#
#  account_id           :integer
#  activity_budget_id   :integer
#  amount               :decimal(19, 4)   default(0.0), not null
#  annotation           :text
#  codes                :jsonb
#  compute_from         :string           not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  credited_item_id     :integer
#  credited_quantity    :decimal(19, 4)
#  currency             :string           not null
#  id                   :integer          not null, primary key
#  label                :text
#  lock_version         :integer          default(0), not null
#  position             :integer
#  pretax_amount        :decimal(19, 4)   default(0.0), not null
#  quantity             :decimal(19, 4)   default(1.0), not null
#  reduction_percentage :decimal(19, 4)   default(0.0), not null
#  sale_id              :integer          not null
#  tax_id               :integer
#  team_id              :integer
#  unit_amount          :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount   :decimal(19, 4)
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variant_id           :integer          not null
#

class SaleItem < Ekylibre::Record::Base
  include PeriodicCalculable
  attr_readonly :sale_id
  enumerize :compute_from, in: %i[unit_pretax_amount pretax_amount amount],
                           default: :unit_pretax_amount, predicates: { prefix: true }
  refers_to :currency
  belongs_to :account
  belongs_to :activity_budget
  belongs_to :team
  belongs_to :sale, inverse_of: :items
  belongs_to :credited_item, class_name: 'SaleItem'
  belongs_to :variant, class_name: 'ProductNatureVariant'
  belongs_to :tax
  # belongs_to :tracking
  has_many :shipment_items
  has_many :shipments, through: :shipment_items
  has_many :credits, class_name: 'SaleItem', foreign_key: :credited_item_id
  has_many :subscriptions, dependent: :destroy
  has_one :subscription, -> { order(:id) }, inverse_of: :sale_item
  has_one :sale_nature, through: :sale, source: :nature
  has_one :product_nature, through: :variant, source: :nature

  delegate :sold?, :invoiced_at, :number, to: :sale
  delegate :currency, :credit, to: :sale, prefix: true
  delegate :name, :short_label, :amount, to: :tax, prefix: true
  delegate :nature, :name, to: :variant, prefix: true
  delegate :unit_name, :name, to: :variant
  delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true
  delegate :subscription_nature, to: :product_nature
  delegate :entity_id, to: :address, prefix: true

  # alias product_nature variant_nature

  acts_as_list scope: :sale
  accepts_nested_attributes_for :subscriptions
  accepts_nested_attributes_for :subscription, reject_if: :all_blank, allow_destroy: true
  sums :sale, :items, :pretax_amount, :amount

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :amount, :pretax_amount, :quantity, :reduction_percentage, :unit_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :annotation, :label, length: { maximum: 500_000 }, allow_blank: true
  validates :compute_from, :currency, :sale, :variant, presence: true
  validates :credited_quantity, :unit_pretax_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :tax, presence: true

  # return all sale items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.invoiced_between(started_at, stopped_at))
  }

  # return all estimates sale items between two accounted_at dates
  scope :estimate_between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.estimate_between(started_at, stopped_at))
  }

  # return all sale items for the consider product_nature
  scope :of_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(product_nature))
  }

  calculable period: :month, column: :pretax_amount, at: 'sales.invoiced_at', name: :sum, joins: :sale

  before_validation do
    self.currency = sale.currency if sale
    self.compute_from ||= :unit_pretax_amount
    if sale_credit
      self.credited_quantity ||= 0.0
      self.quantity = -1 * credited_quantity
    end
    if tax
      precision = Maybe(Nomen::Currency.find(currency)).precision.or_else(2)
      if compute_from_unit_pretax_amount?
        if credited_item
          self.unit_pretax_amount ||= credited_item.unit_pretax_amount
        end
        if sale.reference_number.blank?
          self.unit_amount = nil
          self.pretax_amount = nil
          self.amount = nil
        end
        self.unit_pretax_amount ||= 0.0
        raw_pretax_amount = unit_pretax_amount * quantity * reduction_coefficient
        self.unit_amount ||= tax.amount_of(unit_pretax_amount).round(precision)
        self.pretax_amount ||= raw_pretax_amount.round(precision)
      elsif compute_from_pretax_amount?
        if sale.reference_number.blank?
          self.unit_pretax_amount = nil
          self.unit_amount = nil
          self.amount = nil
        end
        self.pretax_amount ||= 0.0
        raw_pretax_amount = pretax_amount
        self.unit_pretax_amount ||= (raw_pretax_amount / quantity / reduction_coefficient).round(precision)
        self.unit_amount ||= tax.amount_of(unit_pretax_amount).round(precision)
      elsif compute_from_amount?
        if sale.reference_number.blank?
          self.pretax_amount = nil
          self.unit_pretax_amount = nil
          self.unit_amount = nil
        end
        self.amount ||= 0.0
        raw_pretax_amount = tax.pretax_amount_of(self.amount)
        self.pretax_amount ||= raw_pretax_amount.round(precision)
        self.unit_pretax_amount ||= (raw_pretax_amount / quantity / reduction_coefficient).round(precision)
        self.unit_amount ||= tax.amount_of(unit_pretax_amount).round(precision)
      elsif compute_from?
        raise "Invalid compute_from value: #{compute_from.inspect}"
      end
      self.amount ||= tax.amount_of(raw_pretax_amount).round(precision)
    end
    if variant
      self.account_id = variant.nature.category.product_account_id
      self.label = variant.commercial_name
    end
  end

  validate do
    errors.add(:quantity, :invalid) if quantity && quantity.zero?
    # TODO: validates responsible can make reduction and reduction percentage is convenient
  end

  after_save do
    if Preference[:catalog_price_item_addition_if_blank]
      %i[stock sale].each do |usage|
        # set stock catalog price if blank
        catalog = Catalog.by_default!(usage)
        unless variant.catalog_items.of_usage(usage).any? || unit_pretax_amount.blank? || unit_pretax_amount.zero?
          variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: unit_pretax_amount, currency: currency) if catalog
        end
      end
    end
  end

  protect(on: :update) do
    !sale.draft?
  end

  def reduction_coefficient
    (100.0 - (reduction_percentage || 0.0)) / 100.0
  end

  def undelivered_quantity
    quantity - parcel_items.sum(:quantity)
  end

  def designation
    d = label
    d << "\n" + annotation.to_s if annotation.present?
    d << "\n" + tc(:tracking, serial: tracking.serial.to_s) if tracking
    d
  end

  def new_subscription(attributes = {})
    # raise StandardError.new attributes.inspect
    subscription = Subscription.new((attributes || {}).merge(sale_id: sale.id, product_id: product_id, nature_id: product.subscription_nature_id, sale_item_id: id))
    subscription.attributes = attributes
    product = subscription.product
    nature  = subscription.nature
    if nature
      if nature.period?
        subscription.started_at ||= Time.zone.today
        subscription.stopped_at ||= Delay.compute((product.subscription_duration || '1 year') + ', 1 day ago', subscription.started_at)
      else
        subscription.first_number ||= nature.actual_number.to_i
        subscription.last_number ||= subscription.first_number + (product.subscription_quantity || 1) - 1
      end
    end
    subscription.quantity ||= 1
    subscription.address_id ||= sale.delivery_address_id
    subscription.entity_id ||= subscription.address_entity_id if subscription.address
    subscription
  end

  def taxes_amount
    amount - pretax_amount
  end

  def already_credited_quantity
    credits.sum(:quantity)
  end

  def creditable_quantity
    quantity + already_credited_quantity
  end

  # know how many percentage of invoiced VAT to declare
  def payment_ratio
    if sale.affair.balanced?
      1.00
    elsif sale.affair.credit != 0.0
      (1 - (-sale.affair.balance / sale.affair.credit)).to_f
    end
  end
end
