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
# == Table: sale_items
#
#  account_id           :integer
#  amount               :decimal(19, 4)   default(0.0), not null
#  annotation           :text
#  created_at           :datetime         not null
#  creator_id           :integer
#  credited_item_id     :integer
#  currency             :string(3)        not null
#  id                   :integer          not null, primary key
#  indicator_name       :string(120)      not null
#  label                :text
#  lock_version         :integer          default(0), not null
#  position             :integer
#  pretax_amount        :decimal(19, 4)   default(0.0), not null
#  price_id             :integer          not null
#  quantity             :decimal(19, 4)   default(1.0), not null
#  reduced_item_id      :integer
#  reduction_percentage :decimal(19, 4)   default(0.0), not null
#  sale_id              :integer          not null
#  tax_id               :integer
#  unit_price_amount    :decimal(19, 4)
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variant_id           :integer          not null
#


class SaleItem < Ekylibre::Record::Base
  include PeriodicCalculable
  attr_readonly :sale_id
  enumerize :indicator_name, in: Nomen::Indicators.all, predicates: {prefix: true}, default: :population
  belongs_to :account
  belongs_to :sale, inverse_of: :items
  belongs_to :credited_item, class_name: "SaleItem"
  belongs_to :price, class_name: "CatalogPrice"
  belongs_to :variant, class_name: "ProductNatureVariant"
  belongs_to :reduced_item, class_name: "SaleItem"
  belongs_to :tax
  # belongs_to :tracking
  has_many :delivery_items, class_name: "OutgoingDeliveryItem", foreign_key: :sale_item_id
  has_one :reduction, class_name: "SaleItem", foreign_key: :reduced_item_id
  has_many :credits, class_name: "SaleItem", foreign_key: :credited_item_id
  has_many :reductions, class_name: "SaleItem", foreign_key: :reduced_item_id, dependent: :delete_all
  has_many :subscriptions, dependent: :destroy

  accepts_nested_attributes_for :subscriptions
  delegate :sold?, to: :sale
  delegate :currency, to: :sale, prefix: true
  delegate :all_taxes_included?, to: :price
  delegate :name, to: :tax, prefix: true
  delegate :nature, :name, to: :variant, prefix: true
  delegate :unit_name, :name, to: :variant
  delegate :subscribing?, :deliverable?, to: :product_nature, prefix: true
  delegate :entity_id, to: :address, prefix: true

  alias :product_nature :variant_nature

  acts_as_list :scope => :sale
  after_save :set_reduction

  sums :sale, :items, :pretax_amount, :amount

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :reduction_percentage, :unit_price_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :indicator_name, allow_nil: true, maximum: 120
  validates_presence_of :amount, :currency, :indicator_name, :pretax_amount, :price, :quantity, :reduction_percentage, :sale, :variant
  #]VALIDATORS]
  validates_presence_of :tax
  # validates_numericality_of :quantity, greater_than_or_equal_to: 0, :unless => :reduced_item

  scope :not_reduction, -> { where(reduced_item_id: nil) }
  # return all sale items  between two dates
  scope :between, lambda { |started_at, stopped_at|
    joins(:sale).merge(Sale.invoiced_between(started_at, stopped_at))
  }
  # return all sale items for the consider product_nature
  scope :by_product_nature, lambda { |product_nature|
    joins(:variant).merge(ProductNatureVariant.of_natures(product_nature))
  }

  calculable period: :month, at: "invoiced_at", column: :pretax_amount

  before_validation do
    self.pretax_amount ||= 0
    self.amount ||= 0

    if self.price
      self.variant ||= self.price.variant
      self.indicator_name = self.price.indicator_name
      self.unit_price_amount ||= self.price.amount
      self.currency = self.price.currency
      amount = self.quantity * self.unit_price_amount
      if self.tax
        tax_amount = self.tax.compute(amount, self.all_taxes_included?)
        if self.all_taxes_included?
          self.amount = amount
          self.pretax_amount = (self.amount - tax_amount).round(2)
        else
          self.pretax_amount = amount
          self.amount = (self.pretax_amount + tax_amount).round(2)
        end
      else
        self.amount = self.pretax_amount = amount
      end
    elsif self.sale
      self.currency = self.sale.currency
    end

    if self.variant
      self.account_id = self.variant.nature.category.product_account_id
      self.label ||= self.variant.commercial_name
    end

  end


  validate do
    # if self.building
    #   errors.add(:building_id, :building_can_not_transfer_product, :building => self.building.name, :product => self.product.name, :contained_product => self.building.product.name) unless self.building.can_receive?(self.product_id)
    #   if self.tracking
    #     stock = Stocks.where(:product_id => self.product_id, :building_id => self.building_id, :tracking_id => self.tracking_id).first
    #     errors.add(:building_id, :can_not_use_this_tracking, :tracking => self.tracking.name) if stock and stock.virtual_quantity < self.quantity
    #   end
    # end

    # return false if self.pretax_amount.zero? and self.amount.zero? and self.quantity.zero?
    errors.add(:quantity, :invalid) if self.quantity.zero?
    if self.price and self.sale
      errors.add(:price_id, :currency_is_not_sale_currency) if self.price.currency != self.sale.currency
    end
    # TODO validates responsible can make reduction and reduction percentage is convenient
  end

  protect(on: :update) do
    !self.sale.draft?
  end

  def set_reduction
    if self.reduction_percentage > 0 and self.product_nature.reduction_submissive and self.reduced_item_id.nil?
      reduction = self.reduction || self.build_reduction
      reduction.attributes = {:reduced_item_id => self.id, :price_id => self.price_id, :variant_id => self.variant_id, :sale_id => self.sale_id, :quantity => -self.quantity*reduction_percentage/100, :label => tc('reduction_at', :product => self.variant.commercial_name, :percentage => self.reduction_percentage)}
      reduction.save!
    elsif self.reduction
      self.reduction.destroy
    end
  end

  def undelivered_quantity
    self.quantity - self.delivery_items.sum(:quantity)
  end

  # def stock_id
  #   ProductStock.find_by_building_id_and_product_id_and_tracking_id(self.building_id, self.product_id, self.tracking_id).id rescue nil
  # end

  # def stock_id=(value)
  #   value = value.to_i
  #   if value > 0 and stock = ProductStock.find_by_id(value)
  #     self.building_id = stock.building_id
  #     self.tracking_id = stock.tracking_id
  #     self.product_id  = stock.product_id
  #   elsif value < 0 and building = Building.find_by_id(value.abs)
  #     self.building_id = value.abs
  #   end
  # end

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
        subscription.stopped_at ||= Delay.compute((product.subscription_period||'1 year')+", 1 day ago", subscription.started_at)
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


end
