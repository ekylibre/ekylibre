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
# == Table: sale_items
#
#  account_id                 :integer
#  all_taxes_included         :boolean          default(FALSE), not null
#  amount                     :decimal(19, 4)   default(0.0), not null
#  annotation                 :text
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  credited_item_id           :integer
#  currency                   :string           not null
#  id                         :integer          not null, primary key
#  label                      :text
#  lock_version               :integer          default(0), not null
#  position                   :integer
#  pretax_amount              :decimal(19, 4)   default(0.0), not null
#  quantity                   :decimal(19, 4)   default(1.0), not null
#  reduced_unit_amount        :decimal(19, 4)   default(0.0), not null
#  reduced_unit_pretax_amount :decimal(19, 4)   default(0.0), not null
#  reduction_percentage       :decimal(19, 4)   default(0.0), not null
#  sale_id                    :integer          not null
#  tax_id                     :integer
#  unit_amount                :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount         :decimal(19, 4)
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#  variant_id                 :integer          not null
#


class SaleItem < Ekylibre::Record::Base
  include PeriodicCalculable
  attr_readonly :sale_id
  belongs_to :account
  belongs_to :sale, inverse_of: :items
  belongs_to :credited_item, class_name: "SaleItem"
  belongs_to :variant, class_name: "ProductNatureVariant"
  belongs_to :tax
  # belongs_to :tracking
  has_many :delivery_items, class_name: "OutgoingDeliveryItem", foreign_key: :sale_item_id
  has_many :credits, class_name: "SaleItem", foreign_key: :credited_item_id
  has_many :subscriptions, dependent: :destroy
  has_one :sale_nature, through: :sale, source: :nature

  accepts_nested_attributes_for :subscriptions
  delegate :sold?, to: :sale
  delegate :invoiced_at, :number, to: :sale
  delegate :currency, to: :sale, prefix: true
  delegate :name, :short_label, to: :tax, prefix: true
  delegate :nature, :name, to: :variant, prefix: true
  delegate :unit_name, :name, to: :variant
  delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true
  delegate :entity_id, to: :address, prefix: true

  alias :product_nature :variant_nature

  acts_as_list :scope => :sale

  sums :sale, :items, :pretax_amount, :amount

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :reduced_unit_amount, :reduced_unit_pretax_amount, :reduction_percentage, :unit_amount, :unit_pretax_amount, allow_nil: true
  validates_inclusion_of :all_taxes_included, in: [true, false]
  validates_presence_of :amount, :currency, :pretax_amount, :quantity, :reduced_unit_amount, :reduced_unit_pretax_amount, :reduction_percentage, :sale, :unit_amount, :variant
  #]VALIDATORS]
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_presence_of :tax

  # return all sale items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.invoiced_between(started_at, stopped_at))
  }

  # return all estimates sale items between two accounted_at dates
  scope :estimate_between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.estimate_between(started_at, stopped_at))
  }

  # return all sale items for the consider product_nature
  scope :by_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(product_nature))
  }

  calculable period: :month, column: :pretax_amount, at: "invoiced_at"

  before_validation do
    self.pretax_amount ||= 0
    self.amount ||= 0

    if self.sale
      self.currency = self.sale.currency
    end

    precision = 2
    if self.currency
      precision = Nomen::Currencies[self.currency].precision
    end

    self.reduction_percentage ||= 0
    if self.quantity and self.unit_pretax_amount and self.tax
      self.unit_amount = self.tax.amount_of(self.unit_pretax_amount).round(precision)
      self.pretax_amount = (self.quantity * self.unit_pretax_amount * (100.0 - self.reduction_percentage) / 100.0).round(precision)
      self.amount = self.tax.amount_of(self.pretax_amount).round(precision)
      self.reduced_unit_pretax_amount = (self.unit_pretax_amount * (100.0 - self.reduction_percentage) / 100.0)
      self.reduced_unit_amount = (self.unit_amount * (100.0 - self.reduction_percentage) / 100.0)
    end

    if self.variant
      self.account_id = self.variant.nature.category.product_account_id
      self.label ||= self.variant.commercial_name
    end

  end


  validate do
    errors.add(:quantity, :invalid) if self.quantity.zero?
    # TODO validates responsible can make reduction and reduction percentage is convenient
  end

  protect(on: :update) do
    !self.sale.draft?
  end

  def undelivered_quantity
    self.quantity - self.delivery_items.sum(:quantity)
  end

  def designation
    d  = self.label
    d << "\n" + self.annotation.to_s unless self.annotation.blank?
    d << "\n" + tc(:tracking, :serial => self.tracking.serial.to_s) if self.tracking
    return d
  end

  def new_subscription(attributes={})
    #raise StandardError.new attributes.inspect
    subscription = Subscription.new((attributes||{}).merge(:sale_id => self.sale.id, :product_id => self.product_id, :nature_id => self.product.subscription_nature_id, :sale_item_id => self.id))
    subscription.attributes = attributes
    product = subscription.product
    nature  = subscription.nature
    if nature
      if nature.period?
        subscription.started_at ||= Date.today
        subscription.stopped_at ||= Delay.compute((product.subscription_duration||'1 year')+", 1 day ago", subscription.started_at)
      else
        subscription.first_number ||= nature.actual_number.to_i
        subscription.last_number  ||= subscription.first_number+(product.subscription_quantity||1)-1
      end
    end
    subscription.quantity   ||= 1
    subscription.address_id ||= self.sale.delivery_address_id
    subscription.entity_id  ||= subscription.address_entity_id if subscription.address
    subscription
  end


  def taxes_amount
    self.amount - self.pretax_amount
  end

  def credited_quantity
    self.credits.sum(:quantity)
  end

  def uncredited_quantity
    self.quantity + self.credited_quantity
  end

  # know how many percentage of invoiced VAT to declare
  def payment_ratio
    if self.sale.affair.balanced?
      return 1.00
    elsif self.sale.affair.credit != 0.0
      return (1-(-self.sale.affair.balance  / self.sale.affair.credit)).to_f
    end
  end

end
