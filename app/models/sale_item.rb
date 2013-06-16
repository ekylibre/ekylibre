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
# == Table: sale_items
#
#  account_id           :integer
#  amount               :decimal(19, 4)   default(0.0), not null
#  annotation           :text
#  created_at           :datetime         not null
#  creator_id           :integer
#  entity_id            :integer
#  id                   :integer          not null, primary key
#  label                :text
#  lock_version         :integer          default(0), not null
#  origin_id            :integer
#  position             :integer
#  pretax_amount        :decimal(19, 4)   default(0.0), not null
#  price_amount         :decimal(19, 4)
#  price_id             :integer          not null
#  product_id           :integer          not null
#  quantity             :decimal(19, 4)   default(1.0), not null
#  reduction_origin_id  :integer
#  reduction_percentage :decimal(19, 4)   default(0.0), not null
#  sale_id              :integer          not null
#  tax_id               :integer
#  tracking_id          :integer
#  unit                 :string(255)
#  updated_at           :datetime         not null
#  updater_id           :integer
#  warehouse_id         :integer
#


class SaleItem < Ekylibre::Record::Base
  after_save :set_reduction
  attr_accessible :annotation, :price_amount, :price_id, :product_id, :quantity, :reduction_percentage, :sale_id, :tax_id, :unit
  attr_readonly :sale_id
  belongs_to :account
  belongs_to :entity
  belongs_to :sale
  belongs_to :origin, :class_name => "SaleItem"
  belongs_to :price, :class_name => "ProductPrice"
  belongs_to :product
  belongs_to :reduction_origin, :class_name => "SaleItem"
  belongs_to :tax
  belongs_to :tracking
  enumerize :unit, :in => Nomenclatures["units"].list
  has_many :delivery_items, :class_name => "OutgoingDeliveryItem", :foreign_key => :sale_item_id
  has_one :reduction, :class_name => "SaleItem", :foreign_key => :reduction_origin_id
  has_many :credits, :class_name => "SaleItem", :foreign_key => :origin_id
  has_many :reductions, :class_name => "SaleItem", :foreign_key => :reduction_origin_id, :dependent => :delete_all
  has_many :subscriptions, :dependent => :destroy

  accepts_nested_attributes_for :subscriptions
  delegate :sold?, :to => :sale
  delegate :name, :to => :tax, :prefix => true


  acts_as_list :scope => :sale
  acts_as_stockable :mode => :virtual, :if => :sold?
  sums :sale, :items, :pretax_amount, :amount

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :price_amount, :quantity, :reduction_percentage, :allow_nil => true
  validates_length_of :unit, :allow_nil => true, :maximum => 255
  validates_presence_of :amount, :pretax_amount, :price, :product, :quantity, :reduction_percentage, :sale
  #]VALIDATORS]
  validates_presence_of :tax


  before_validation do
    # check_reservoir = true
    if not self.price and self.sale and self.product
      self.price = self.product.price(:listing => self.sale.client.sale_price_listing)
    end
    # self.product = self.price.product if self.price
    if self.product
      self.account_id = self.product.nature.product_account_id
      self.unit = self.product.unit
      if self.product.nature.storable
      #   self.building_id ||= self.product.stocks.first.building_id if self.product.stocks.count > 0
      # else
      #   self.building_id = nil
      end
      self.label ||= self.product.nature.commercial_name
    end
    self.price_amount ||= 0

    # TODO Repairs that
    # if self.price_amount > 0
    #   price = ProductPriceTemplate.create!(:pretax_amount => self.price_amount, :tax_id => self.tax_id||0, :entity_id => Entity.of_company.id, :active => false, :product_id => self.product_id, :listing_id => self.sale.client.sale_price_listing_id)
    #   self.price = price
    # end

    if self.price
      if self.reduction_origin_id.nil?
        if self.quantity
          self.pretax_amount = (self.price.pretax_amount*self.quantity).round(2)
          self.amount = (self.price.amount*self.quantity).round(2)
        elsif self.pretax_amount
          q = self.pretax_amount/self.price.pretax_amount
          self.quantity = q.round(2)
          self.amount = (q*self.price.amount).round(2)
        elsif self.amount
          q = self.amount/self.price.amount
          self.quantity = q.round(2)
          self.pretax_amount = (q*self.price.pretax_amount).round(2)
        end
      else
        self.pretax_amount = (self.price.pretax_amount*self.quantity).round(2)
        self.amount = (self.price.amount*self.quantity).round(2)
      end

      self.tax ||= self.price.tax
      return true
    end


    #     if self.building.reservoir && self.building.product_id != self.product_id
    #       check_reservoir = false
    #       errors.add(:building_id, :building_can_not_transfer_product, :building => self.building.name, :product => self.product.name, :contained_product => self.building.product.name, :account_id => 0, :unit => self.unit)
    #     end
    #     check_reservoir
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
    if self.price
      errors.add(:price_id, :currency_is_not_sale_currency) if self.price.currency != self.sale.currency
      if self.product
        errors.add(:price_id, :invalid) unless self.price.product_nature_id == self.product.nature_id
      end
    end
    # TODO validates responsible can make reduction and reduction percentage is convenient
  end

  protect(:on => :update) do
    return self.sale.draft?
  end

  def set_reduction
    if self.reduction_percentage > 0 and self.product.reduction_submissive and self.reduction_origin_id.nil?
      reduction = self.reduction || self.build_reduction
      reduction.attributes = {:reduction_origin_id => self.id, :price_id => self.price_id, :product_id => self.product_id, :sale_id => self.sale_id, :building_id => self.building_id, :quantity => -self.quantity*reduction_percentage/100, :label => tc('reduction_on', :product => self.product.commercial_name, :percentage => self.reduction_percentage)}
      reduction.save!
    elsif self.reduction
      self.reduction.destroy
    end
  end

  def undelivered_quantity
    self.quantity - self.delivery_items.sum(:quantity)
  end

  def product_name
    self.product ? self.product.name : tc(:no_product)
  end

  def stock_id
    ProductStock.find_by_building_id_and_product_id_and_tracking_id(self.building_id, self.product_id, self.tracking_id).id rescue nil
  end

  def stock_id=(value)
    value = value.to_i
    if value > 0 and stock = ProductStock.find_by_id(value)
      self.building_id = stock.building_id
      self.tracking_id = stock.tracking_id
      self.product_id  = stock.product_id
    elsif value < 0 and building = Building.find_by_id(value.abs)
      self.building_id = value.abs
    end
  end

  def designation
    d  = self.label
    d << "\n"+self.annotation.to_s unless self.annotation.blank?
    d << "\n"+tc(:tracking, :serial => self.tracking.serial.to_s) if self.tracking
    return d
  end

  def subscribing?
    self.product.nature == "subscrip"
  end

  def new_subscription(attributes={})
    #raise Exception.new attributes.inspect
    subscription = Subscription.new((attributes||{}).merge(:sale_id => self.sale.id, :product_id => self.product_id, :nature_id => self.product.subscription_nature_id, :sale_item_id => self.id))
    subscription.attributes = attributes
    product = subscription.product
    nature  = subscription.nature
    if nature
      if nature.nature == "period"
        subscription.started_on ||= Date.today
        subscription.stopped_on ||= Delay.compute((product.subscription_period||'1 year')+", 1 day ago", subscription.started_on)
      else
        subscription.first_number ||= nature.actual_number.to_i
        subscription.last_number  ||= subscription.first_number+(product.subscription_quantity||1)-1
      end
    end
    subscription.quantity   ||= 1
    subscription.address_id ||= self.sale.delivery_address_id
    subscription.entity_id  ||= subscription.address.entity_id if subscription.address
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
