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
# == Table: purchase_items
#
#  account_id             :integer          not null
#  activity_budget_id     :integer
#  amount                 :decimal(19, 4)   default(0.0), not null
#  annotation             :text
#  created_at             :datetime         not null
#  creator_id             :integer
#  currency               :string           not null
#  depreciable_product_id :integer
#  fixed                  :boolean          default(FALSE), not null
#  fixed_asset_id         :integer
#  id                     :integer          not null, primary key
#  label                  :text
#  lock_version           :integer          default(0), not null
#  position               :integer
#  preexisting_asset      :boolean
#  pretax_amount          :decimal(19, 4)   default(0.0), not null
#  purchase_id            :integer          not null
#  quantity               :decimal(19, 4)   default(1.0), not null
#  reduction_percentage   :decimal(19, 4)   default(0.0), not null
#  tax_id                 :integer          not null
#  team_id                :integer
#  unit_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount     :decimal(19, 4)   not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer          not null
#

class PurchaseItem < Ekylibre::Record::Base
  include PeriodicCalculable
  refers_to :currency
  belongs_to :account
  belongs_to :activity_budget
  belongs_to :team
  belongs_to :purchase, inverse_of: :items
  belongs_to :variant, class_name: 'ProductNatureVariant', inverse_of: :purchase_items
  belongs_to :tax
  belongs_to :fixed_asset, inverse_of: :purchase_items
  belongs_to :depreciable_product, class_name: 'Product'
  has_many :parcel_items
  has_many :products, through: :parcel_items
  has_one :product_nature_category, through: :variant, source: :category
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :amount, :pretax_amount, :quantity, :reduction_percentage, :unit_amount, :unit_pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :annotation, :label, length: { maximum: 500_000 }, allow_blank: true
  validates :account, :currency, :purchase, :tax, :variant, presence: true
  validates :fixed, inclusion: { in: [true, false] }
  validates :preexisting_asset, inclusion: { in: [true, false] }, allow_blank: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :account, :tax, :reduction_percentage, presence: true
  validates_associated :fixed_asset

  delegate :invoiced_at, :journal_entry, :number, :computation_method, :computation_method_quantity_tax?, :computation_method_tax_quantity?, :computation_method_adaptative?, :computation_method_manual?, to: :purchase
  delegate :purchased?, :draft?, :order?, :supplier, to: :purchase
  delegate :currency, to: :purchase, prefix: true
  delegate :name, to: :variant, prefix: true
  delegate :name, :amount, :short_label, to: :tax, prefix: true
  # delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true

  # accepts_nested_attributes_for :fixed_asset

  alias_attribute :name, :label

  acts_as_list scope: :purchase
  sums :purchase, :items, :pretax_amount, :amount

  calculable period: :month, column: :pretax_amount, at: 'purchases.invoiced_at', name: :sum, joins: :purchase

  # return all purchase items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:purchase).merge(Purchase.invoiced_between(started_at, stopped_at))
  }
  # return all sale items for the consider product_nature
  scope :of_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(product_nature))
  }

  # return all sale items for the consider product_nature
  scope :of_product_nature_category, lambda { |product_nature_category|
    joins(:variant).merge(ProductNatureVariant.of_categories(product_nature_category))
  }

  before_validation do
    self.currency = purchase_currency if purchase

    self.quantity ||= 0
    self.reduction_percentage ||= 0

    if preexisting_asset
      self.depreciable_product = nil
    else
      self.fixed_asset = nil
    end

    if tax && unit_pretax_amount
      precision = Maybe(Nomen::Currency.find(currency)).precision.or_else(2)
      self.unit_amount = tax.amount_of(unit_pretax_amount)
      raw_pretax_amount = nil
      if pretax_amount.nil? || pretax_amount.zero?
        raw_pretax_amount = unit_pretax_amount * self.quantity * reduction_coefficient
        self.pretax_amount = raw_pretax_amount.round(precision)
      end
      if amount.nil? || amount.zero?
        self.amount = tax.amount_of(raw_pretax_amount || pretax_amount).round(precision)
      end
    end

    if variant
      self.label ||= variant.commercial_name
      self.account = if fixed && purchase.purchased?
                       # select outstanding_assets during purchase
                       Account.find_or_import_from_nomenclature(:outstanding_assets)
                     else
                       variant.charge_account || Account.find_in_nomenclature(:expenses)
                     end
    end
  end

  after_update do
    if fixed && fixed_asset && purchase.purchased?
      fixed_asset.reload
      amount_difference = pretax_amount.to_f - pretax_amount_was.to_f
      fixed_asset.add_amount(amount_difference) if fixed_asset && amount_difference.nonzero?
    end
    true
  end

  after_destroy do
    if fixed && fixed_asset && purchase.purchased?
      fixed_asset.add_amount(-pretax_amount.to_f) if fixed_asset
    end
    true
  end
  validate do
    errors.add(:currency, :invalid) if purchase && currency != purchase_currency
    errors.add(:quantity, :invalid) if self.quantity.zero?
  end

  after_save do
    if Preference[:catalog_price_item_addition_if_blank]
      %i[stock purchase].each do |usage|
        # set stock catalog price if blank
        catalog = Catalog.by_default!(usage)
        next if catalog.nil? || variant.catalog_items.of_usage(usage).any? ||
                unit_pretax_amount.blank? || unit_pretax_amount.zero?
        variant.catalog_items.create!(
          catalog: catalog,
          amount: unit_pretax_amount, currency: currency
        )
      end
    end
  end

  def new_fixed_asset
    # Create asset
    asset_attributes = {
      currency: currency,
      started_on: purchase.invoiced_at.to_date,
      depreciable_amount: pretax_amount.to_f,
      depreciation_period: Preference.get(:default_depreciation_period).value,
      depreciation_method: variant.fixed_asset_depreciation_method || :simplified_linear,
      depreciation_percentage: variant.fixed_asset_depreciation_percentage || 20,
      journal: Journal.find_by(nature: :purchases),
      asset_account: variant.fixed_asset_account, # 2
      allocation_account: variant.fixed_asset_allocation_account, # 28
      expenses_account: variant.fixed_asset_expenses_account, # 68
      product: depreciable_product
    }
    asset_name = parcel_items.collect(&:name).to_sentence if products.any?
    asset_name ||= name
    name_duplicate_count = FixedAsset.where(name: asset_name).count
    unless name_duplicate_count.zero?
      unique_identifier = (name_duplicate_count + 1).to_s(36).upcase
      asset_name = "#{asset_name} #{unique_identifier}"
    end
    asset_attributes[:name] = asset_name

    build_fixed_asset(asset_attributes)
  end

  def update_fixed_asset
    return unless fixed
    if preexisting_asset
      return errors.add(:fixed_asset, :fixed_asset_missing) unless fixed_asset
      return errors.add(:fixed_asset, :fixed_asset_cannot_be_modified) unless fixed_asset.draft?
      fixed_asset.reload
      fixed_asset.add_amount(pretax_amount.to_f)
    else
      a = new_fixed_asset
      a.save!
      self.fixed_asset = a
      self.preexisting_asset = true
      save!
    end
  end

  def reduction_coefficient
    (100.0 - reduction_percentage) / 100.0
  end

  def product_name
    variant.name
  end

  def taxes_amount
    amount - pretax_amount
  end

  def designation
    d = product_name
    d << "\n" + annotation.to_s if annotation.present?
    d << "\n" + tc(:tracking, serial: tracking.serial.to_s) if tracking
    d
  end

  def undelivered_quantity
    self.quantity - parcel_items.sum(:quantity)
  end

  # know how many percentage of invoiced VAT to declare
  def payment_ratio
    if purchase.affair.balanced?
      1.00
    elsif purchase.affair.debit != 0.0
      (1 - (purchase.affair.balance / purchase.affair.debit)).to_f
    end
  end
end
