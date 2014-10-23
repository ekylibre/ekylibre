# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  account_id        :integer          not null
#  amount            :decimal(19, 4)   default(0.0), not null
#  annotation        :text
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string(3)        not null
#  id                :integer          not null, primary key
#  indicator_name    :string(120)      not null
#  label             :text
#  lock_version      :integer          default(0), not null
#  position          :integer
#  pretax_amount     :decimal(19, 4)   default(0.0), not null
#  purchase_id       :integer          not null
#  quantity          :decimal(19, 4)   default(1.0), not null
#  tax_id            :integer          not null
#  unit_price_amount :decimal(19, 4)   not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#  variant_id        :integer          not null
#


class PurchaseItem < Ekylibre::Record::Base
  belongs_to :account
  belongs_to :purchase, inverse_of: :items
  # belongs_to :price, class_name: "CatalogPrice"
  belongs_to :variant, class_name: "ProductNatureVariant", inverse_of: :purchase_items
  belongs_to :tax
  has_many :delivery_items, class_name: "IncomingDeliveryItem", foreign_key: :purchase_item_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :unit_price_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :indicator_name, allow_nil: true, maximum: 120
  validates_presence_of :account, :amount, :currency, :indicator_name, :pretax_amount, :purchase, :quantity, :tax, :unit_price_amount, :variant
  #]VALIDATORS]
  validates_presence_of :account, :tax
  # validates_presence_of :pretax_amount, :price # Already defined in auto-validators
  # validates_uniqueness_of :tracking_serial, :scope => :price_id, allow_nil: true, if: Proc.new{|pl| !pl.tracking_serial.blank? }, :allow_blank => true

  delegate :purchased?, :draft?, :order?, :supplier, to: :purchase
  delegate :currency, to: :purchase, prefix: true
  # delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true

  alias_attribute :name, :label

  acts_as_list :scope => :purchase
  sums :purchase, :items, :pretax_amount, :amount

  before_validation do
    self.pretax_amount ||= 0
    self.amount ||= 0
    self.currency = self.purchase_currency
    if self.variant
      self.account   ||= self.variant.charge_account || Account.find_in_chart(:expenses)
      self.label     ||= self.variant.commercial_name
      self.currency  ||= Preference.get(:currency).value
      self.indicator_name ||= :population.to_s
    end
    if self.quantity and self.unit_price_amount
      amount = self.quantity * self.unit_price_amount
      if self.tax
        tax_amount = self.tax.compute(amount, false)
        self.pretax_amount = amount
        self.amount = (self.pretax_amount + tax_amount).round(2)
      else
        self.amount = self.pretax_amount = amount
      end
    end
  end

  validate do
    errors.add(:currency, :invalid) if self.currency != self.purchase.currency
    errors.add(:quantity, :invalid) if self.quantity.zero?
    # # Validate that tracking serial is not used for a different product
    # producer = self.purchase.supplier
    # unless self.tracking_serial.blank?
    #   errors.add(:tracking_serial, :serial_already_used_with_an_other_product) if producer.has_another_tracking?(self.tracking_serial, self.product_id)
    # end
    # if self.price and self.purchase
    #   errors.add(:price_id, :invalid) if self.price.currency != self.purchase.currency
    # end
    # errors.add(:quantity, :invalid) if self.quantity.zero?
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

end
