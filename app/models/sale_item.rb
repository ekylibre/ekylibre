# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
#  account_id             :integer(4)
#  accounting_label       :string
#  activity_budget_id     :integer(4)
#  amount                 :decimal(19, 4)   default(0.0), not null
#  annotation             :text
#  catalog_item_id        :integer(4)
#  catalog_item_update    :boolean          default(FALSE)
#  codes                  :jsonb
#  compute_from           :string           not null
#  conditioning_quantity  :decimal(20, 10)  not null
#  conditioning_unit_id   :integer(4)       not null
#  created_at             :datetime         not null
#  creator_id             :integer(4)
#  credited_item_id       :integer(4)
#  credited_quantity      :decimal(19, 4)
#  currency               :string           not null
#  depreciable_product_id :integer(4)
#  fixed                  :boolean          default(FALSE), not null
#  fixed_asset_id         :integer(4)
#  id                     :integer(4)       not null, primary key
#  label                  :text
#  lock_version           :integer(4)       default(0), not null
#  position               :integer(4)
#  preexisting_asset      :boolean
#  pretax_amount          :decimal(19, 4)   default(0.0), not null
#  quantity               :decimal(19, 4)   not null
#  reduction_percentage   :decimal(19, 4)   default(0.0), not null
#  sale_id                :integer(4)       not null
#  shipment_item_id       :integer(4)
#  tax_id                 :integer(4)
#  team_id                :integer(4)
#  unit_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount     :decimal(19, 4)
#  updated_at             :datetime         not null
#  updater_id             :integer(4)
#  variant_id             :integer(4)       not null
#

class SaleItem < ApplicationRecord
  include PeriodicCalculable
  attr_readonly :sale_id
  enumerize :compute_from, in: %i[unit_pretax_amount pretax_amount amount],
                           default: :unit_pretax_amount, predicates: { prefix: true }
  refers_to :currency
  belongs_to :account
  belongs_to :activity_budget
  belongs_to :team
  belongs_to :fixed_asset
  belongs_to :sale, inverse_of: :items
  belongs_to :credited_item, class_name: 'SaleItem'
  belongs_to :depreciable_product, class_name: 'Product'
  belongs_to :variant, class_name: 'ProductNatureVariant'
  belongs_to :tax
  belongs_to :conditioning_unit, class_name: 'Unit'
  belongs_to :catalog_item
  # belongs_to :tracking
  # for a sale order who create shipments 1 order => n shipments
  has_many :shipment_items
  has_many :shipments, through: :shipment_items
  # for a sale creating from shipments n shipments => 1 sale
  belongs_to :shipment_item, inverse_of: :sale_item, foreign_key: :shipment_item_id
  has_one :shipment, through: :shipment_item
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
  delegate :dimension, :of_dimension?, to: :unit

  # alias product_nature variant_nature
  alias_attribute :unit, :conditioning_unit

  acts_as_list scope: :sale
  accepts_nested_attributes_for :subscriptions
  accepts_nested_attributes_for :subscription, reject_if: :all_blank, allow_destroy: true
  sums :sale, :items, :pretax_amount, :amount

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounting_label, length: { maximum: 500 }, allow_blank: true
  validates :amount, :pretax_amount, :quantity, :reduction_percentage, :unit_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :annotation, :label, length: { maximum: 500_000 }, allow_blank: true
  validates :catalog_item_update, :preexisting_asset, inclusion: { in: [true, false] }, allow_blank: true
  validates :compute_from, :conditioning_unit, :currency, :sale, :variant, presence: true
  validates :conditioning_quantity, presence: true, numericality: { greater_than: -10_000_000_000, less_than: 10_000_000_000 }
  validates :credited_quantity, :unit_pretax_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :fixed, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :tax, presence: true
  validates :quantity, presence: true, exclusion: { in: [0], message: :invalid }
  validates :conditioning_unit, conditioning: true

  # return all sale items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.invoiced_between(started_at, stopped_at))
  }

  # return all estimates sale items between two accounted_at dates
  scope :estimate_between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.estimate_between(started_at, stopped_at))
  }

  # return all estimates sale items between two accounted_at dates
  scope :of_sale_nature, lambda { |sale_nature|
    joins(:sale).merge(Sale.of_nature(sale_nature))
  }

  # return all sale items for the consider product_nature
  scope :of_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(Array(product_nature)))
  }

  # return all sale items for the consider product_nature_variant
  scope :of_variants, lambda { |variants|
    joins(:variant).merge(ProductNatureVariant.where(id: variants.pluck(:id)))
  }

  # return all sale items for the consider product_nature
  scope :of_product_nature_category, lambda { |product_nature_category|
    joins(:variant).merge(ProductNatureVariant.of_category(product_nature_category))
  }

  scope :active, -> { includes(:sale).where.not(sales: { state: %i[refused aborted] }).order(created_at: :desc) }
  scope :invoiced_on_or_after, ->(date) { includes(:sale).where("invoiced_at >= ? OR invoiced_at IS NULL", date) }
  scope :fixed, -> { where(fixed: true) }
  scope :linkable_to_fixed_asset, -> { active.fixed.where(fixed_asset_id: nil) }
  scope :linked_to_fixed_asset, -> { active.where.not(fixed_asset_id: nil) }

  calculable period: :month, column: :pretax_amount, at: 'sales.invoiced_at', name: :sum, joins: :sale

  before_validation do
    if sale && sale_credit
      self.credited_quantity ||= 0.0
      self.conditioning_quantity ||= -1 * credited_quantity
    end
    self.quantity ||= UnitComputation.convert_into_variant_population(variant, conditioning_quantity, conditioning_unit) if conditioning_unit && conditioning_quantity
    self.quantity ||= 1
    self.conditioning_quantity ||= 1
    self.currency = sale.currency if sale
    self.compute_from ||= :unit_pretax_amount
    if tax
      precision = Maybe(Onoma::Currency.find(currency)).precision.or_else(2)
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
        self.quantity ||= 0.0
        raw_pretax_amount = unit_pretax_amount * conditioning_quantity * reduction_coefficient if conditioning_quantity
        self.unit_amount ||= tax.amount_of(unit_pretax_amount).round(precision)
        self.pretax_amount ||= raw_pretax_amount.round(precision) if raw_pretax_amount
      elsif compute_from_pretax_amount?
        if sale.reference_number.blank?
          self.unit_pretax_amount = nil
          self.unit_amount = nil
          self.amount = nil
        end
        self.pretax_amount ||= 0.0
        raw_pretax_amount = pretax_amount

        raw_unit_pretax_amount = (raw_pretax_amount / quantity / reduction_coefficient).round(precision)
        self.unit_pretax_amount ||= raw_unit_pretax_amount

        if raw_unit_pretax_amount.nan?
          self.unit_pretax_amount = 0.0
        end
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
      self.amount ||= tax.amount_of(raw_pretax_amount).round(precision) if raw_pretax_amount
    end
    if variant
      self.account_id = variant.category.product_account_id
      self.label = variant.commercial_name
    end
  end

  after_save do
    unlink_fixed_asset(attribute_before_last_save(:fixed_asset_id)) if attribute_before_last_save(:fixed_asset_id)
    link_fixed_asset(fixed_asset_id) if fixed_asset_id
    next unless Preference[:catalog_price_item_addition_if_blank] && sale.invoice?

    %i[stock sale].each do |usage|
      # set stock catalog price if blank
      next unless catalog = Catalog.by_default!(usage)

      item = CatalogItem.find_by(catalog: catalog, variant: variant, unit: conditioning_unit, started_at: sale.invoiced_at)
      next if item || unit_pretax_amount.blank? || unit_pretax_amount.zero?

      variant.catalog_items.create!(catalog: catalog,
                                    all_taxes_included: false,
                                    amount: unit_pretax_amount,
                                    currency: currency,
                                    sale_item: self,
                                    started_at: sale.invoiced_at,
                                    unit: conditioning_unit)
    end
  end

  after_destroy do
    unlink_fixed_asset(attribute_was(:fixed_asset_id)) if attribute_was(:fixed_asset_id)
  end

  protect(on: :update) do
    return false if sale.draft? || sale.order?

    authorized_columns = %w[fixed_asset_id depreciable_product_id updated_at]
    (changes_to_save.keys - authorized_columns).any?
  end

  def unlink_fixed_asset(former_id)
    # Instead of dependent: :nullify since we need to update more attributes than just the foreign key and it doesn't trigger callbacks
    FixedAsset.find(former_id).update!(sale_id: nil, sale_item_id: nil, tax_id: nil, selling_amount: nil, pretax_selling_amount: nil, sold_on: nil)
  end

  def link_fixed_asset(fixed_asset_id)
    FixedAsset.find(fixed_asset_id).update!(sale_id: sale.id, sale_item_id: id, tax_id: tax_id, selling_amount: amount, pretax_selling_amount: pretax_amount, sold_on: sale.invoiced_at&.to_date)
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

  def base_unit_amount
    coeff = conditioning_unit&.coefficient
    (unit_pretax_amount / coeff).round(2) if coeff && coeff != 1
  end

  def already_credited_quantity
    credits.sum(:conditioning_quantity)
  end

  def creditable_quantity
    conditioning_quantity + already_credited_quantity
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
