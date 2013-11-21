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
# == Table: purchase_items
#
#  account_id        :integer          not null
#  amount            :decimal(19, 4)   default(0.0), not null
#  annotation        :text
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string(3)        not null
#  id                :integer          not null, primary key
#  indicator         :string(120)      not null
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
  # attr_accessible :annotation, :price_id, :product_id, :quantity, :tracking_serial, :price_amount, :purchase_id, :tax_id, :unit
  belongs_to :account
  # belongs_to :building, foreign_key: :warehouse_id
  belongs_to :purchase, inverse_of: :items
  # belongs_to :price, class_name: "CatalogPrice"
  belongs_to :variant, class_name: "ProductNatureVariant"
  belongs_to :tax
  # enumerize :unit, in: Nomen::Units.all
  has_many :delivery_items, class_name: "IncomingDeliveryItem", foreign_key: :purchase_item_id

  # accepts_nested_attributes_for :price
  delegate :purchased?, :draft?, :order?, :supplier, to: :purchase
  delegate :currency, to: :purchase, prefix: true
  # delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true

  acts_as_list :scope => :purchase
  acts_as_stockable :mode => :virtual, :direction => :in, :if => :purchased?
  sums :purchase, :items, :pretax_amount, :amount

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :unit_price_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :indicator, allow_nil: true, maximum: 120
  validates_presence_of :account, :amount, :currency, :indicator, :pretax_amount, :purchase, :quantity, :tax, :unit_price_amount, :variant
  #]VALIDATORS]
  validates_presence_of :account
  # validates_presence_of :pretax_amount, :price # Already defined in auto-validators
  # validates_uniqueness_of :tracking_serial, :scope => :price_id, allow_nil: true, if: Proc.new{|pl| !pl.tracking_serial.blank? }, :allow_blank => true


  before_validation do
    self.currency = self.purchase_currency
    if self.variant
      self.account   ||= variant.charge_account || Account.find_in_chart(:charges)
      self.label     ||= self.variant.commercial_name
      self.currency  ||= Preference.get(:currency).value
      self.indicator ||= :population.to_s
    end
  end

  validate do
    errors.add(:currency, :invalid) if self.currency != self.purchase.currency
    # Validate that tracking serial is not used for a different product
    # producer = self.purchase.supplier
    # unless self.tracking_serial.blank?
      # errors.add(:tracking_serial, :serial_already_used_with_an_other_product) if producer.has_another_tracking?(self.tracking_serial, self.product_id)
    # end
    # if self.price and self.purchase
      # errors.add(:price_id, :invalid) if self.price.currency != self.purchase.currency
    # end
    # errors.add(:quantity, :invalid) if self.quantity.zero?
  end

  #def name
  #  options = {:product => self.product.name, :quantity => quantity.to_s, :amount => self.price.amount, :currency => self.price.currency.name} # , :unit => self.unit.name
  #  if self.tracking
   #   options[:tracking] = self.tracking.name
  #    tc(:name_with_tracking, options)
  #  else
  #    tc(:name, options)
  # end
  # end

  def product_name
    self.variant.name
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  def designation
    d  = self.product_name
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d += "\n"+tc(:tracking, :serial => self.tracking.serial.to_s) if self.tracking
    d
  end

  def undelivered_quantity
    return self.quantity-self.delivery_items.sum(:quantity)
  end

  def label
    self.variant.name
  end

end
