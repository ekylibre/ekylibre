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
# == Table: purchase_items
#
#  account_id         :integer          not null
#  amount             :decimal(19, 4)   default(0.0), not null
#  annotation         :text
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string           not null
#  fixed              :boolean          default(FALSE), not null
#  id                 :integer          not null, primary key
#  label              :text
#  lock_version       :integer          default(0), not null
#  position           :integer
#  pretax_amount      :decimal(19, 4)   default(0.0), not null
#  purchase_id        :integer          not null
#  quantity           :decimal(19, 4)   default(1.0), not null
#  reference_value    :string           not null
#  tax_id             :integer          not null
#  unit_amount        :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount :decimal(19, 4)   not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer          not null
#


class PurchaseItem < Ekylibre::Record::Base
  include PeriodicCalculable
  enumerize :reference_value, in: [:unit_pretax_amount, :unit_amount, :pretax_amount, :amount], default: :unit_pretax_amount
  belongs_to :account
  belongs_to :purchase, inverse_of: :items
  # belongs_to :price, class_name: "CatalogItem"
  belongs_to :variant, class_name: "ProductNatureVariant", inverse_of: :purchase_items
  belongs_to :tax
  has_many :delivery_items, class_name: "IncomingDeliveryItem", foreign_key: :purchase_item_id
  has_many :products, through: :delivery_items
  has_one :financial_asset, foreign_key: :purchase_item_id, inverse_of: :purchase_item
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :unit_amount, :unit_pretax_amount, allow_nil: true
  validates_inclusion_of :fixed, in: [true, false]
  validates_presence_of :account, :amount, :currency, :pretax_amount, :purchase, :quantity, :reference_value, :tax, :unit_amount, :unit_pretax_amount, :variant
  #]VALIDATORS]
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_presence_of :account, :tax
  validates_associated :financial_asset
  # validates_uniqueness_of :tracking_serial, :scope => :price_id, allow_nil: true, if: Proc.new{|pl| !pl.tracking_serial.blank? }, :allow_blank => true

  delegate :invoiced_at, :number, to: :purchase
  delegate :purchased?, :draft?, :order?, :supplier, to: :purchase
  delegate :currency, to: :purchase, prefix: true
  delegate :name, to: :variant, prefix: true
  delegate :name, :short_label, to: :tax, prefix: true
  # delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true

  accepts_nested_attributes_for :financial_asset

  alias_attribute :name, :label

  acts_as_list :scope => :purchase
  sums :purchase, :items, :pretax_amount, :amount

  calculable period: :month, at: "invoiced_at", column: :pretax_amount

  # return all purchase items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:purchase).merge(Purchase.invoiced_between(started_at, stopped_at))
  }
  # return all sale items for the consider product_nature
  scope :by_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(product_nature))
  }

  # return all sale items for the consider product_nature
  scope :by_product_nature_category, lambda { |product_nature_category|
    joins(:variant).merge(ProductNatureVariant.of_categories(product_nature_category))
  }

  before_validation do
    self.pretax_amount ||= 0
    self.amount ||= 0

    if self.purchase
      self.currency = self.purchase_currency
    end

    precision = 2
    if self.currency
      precision = Nomen::Currencies[self.currency].precision
    end

    if self.quantity and self.unit_pretax_amount and self.tax
      self.unit_amount = self.tax.amount_of(self.unit_pretax_amount).round(precision)
      self.pretax_amount = (self.quantity * self.unit_pretax_amount).round(precision)
      self.amount = self.tax.amount_of(self.pretax_amount).round(precision)
    end

    if self.variant
      if self.fixed
        self.account = self.variant.financial_asset_account || Account.find_in_chart(:financial_assets)
      else
        self.account = self.variant.charge_account || Account.find_in_chart(:expenses)
      end
      self.label     ||= self.variant.commercial_name
    end
  end


  validate do
    if self.purchase
      errors.add(:currency, :invalid) if self.currency != self.purchase_currency
    end
    errors.add(:quantity, :invalid) if self.quantity.zero?
  end

  before_validation do
    if variant = self.variant and variant.depreciable? and self.fixed and !self.financial_asset
      # Create asset
      attributes = {
        started_on: self.purchase.invoiced_at.to_date,
        depreciable_amount: self.pretax_amount,
        depreciation_method: variant.financial_asset_depreciation_method,
        depreciation_percentage: variant.financial_asset_depreciation_percentage,
        journal: Journal.where(nature: :various).first,
        allocation_account: variant.financial_asset_allocation_account, #28
        expenses_account: variant.financial_asset_expenses_account #68
      }
      if self.products.any?
        attributes[:name] = self.delivery_items.collect(&:name).to_sentence
      end
      attributes[:name] ||= self.name

      if FinancialAsset.find_by(name: attributes[:name])
        attributes[:name] << " " + rand(FinancialAsset.count * 36 ** 3).to_s(36).upcase
      end
      self.build_financial_asset(attributes)
    end
  end

  def product_name
    self.variant.name
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  def designation
    d  = self.product_name
    d << "\n" + self.annotation.to_s unless self.annotation.blank?
    d << "\n" + tc(:tracking, serial: self.tracking.serial.to_s) if self.tracking
    d
  end

  def undelivered_quantity
    return self.quantity - self.delivery_items.sum(:quantity)
  end

  # know how many percentage of invoiced VAT to declare
  def payment_ratio
    if self.purchase.affair.balanced?
      return 1.00
    elsif self.purchase.affair.debit != 0.0
      return (1-(self.purchase.affair.balance  / self.purchase.affair.debit)).to_f
    end
  end

end
