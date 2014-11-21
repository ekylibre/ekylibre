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
# == Table: catalog_items
#
#  all_taxes_included     :boolean          not null
#  amount                 :decimal(19, 4)   not null
#  catalog_id             :integer          not null
#  commercial_description :text
#  commercial_name        :string(255)
#  created_at             :datetime         not null
#  creator_id             :integer
#  currency               :string(3)        not null
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string(255)      not null
#  reference_tax_id       :integer
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer          not null
#


# CatalogItem stores all the prices used in sales and purchases.
class CatalogItem < Ekylibre::Record::Base
  enumerize :currency, in: Nomen::Currencies.all
  belongs_to :variant, class_name: "ProductNatureVariant"
  belongs_to :reference_tax, class_name: "Tax"
  belongs_to :catalog
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :commercial_name, :name, allow_nil: true, maximum: 255
  validates_inclusion_of :all_taxes_included, in: [true, false]
  validates_presence_of :amount, :catalog, :currency, :name, :variant
  #]VALIDATORS]

  # delegate :product_nature_id, :product_nature, to: :template
  delegate :name, to: :variant, prefix: true
  delegate :unit_name, to: :variant
  delegate :usage, to: :catalog

  scope :of_variant, lambda { |variant|
    where(variant_id: variant.id)
  }

  scope :of_usage, lambda { |usage|
    joins(:catalog).merge(Catalog.of_usage(usage))
  }

  scope :saleables, lambda {
    joins(variant: :category).where(product_nature_categories: {saleable: true})
  }

  before_validation on: :create do
    self.currency = Preference[:currency] if self.currency.blank?
  end

  before_validation do
    if self.amount
      self.amount = self.amount.round(4)
    end
    self.name = self.commercial_name
    if self.commercial_name.blank? and self.variant
      self.name = self.variant_name
    end
  end

  # def compute(quantity = nil, pretax_amount = nil, amount = nil)
  #   if quantity
  #     pretax_amount = self.pretax_amount*quantity
  #     amount = self.amount*quantity
  #   elsif pretax_amount
  #     quantity = pretax_amount/self.pretax_amount
  #     amount = quantity*self.amount
  #   elsif amount
  #     quantity = amount/self.amount
  #     pretax_amount = quantity*self.amount
  #   elsif
  #     raise ArgumentError.new("At least one argument must be given")
  #   end
  #   return quantity.round(4), pretax_amount.round(2), amount.round(2)
  # end

  # # Give a price for a given product
  # # Options are: :pretax_amount, :amount,
  # # :template, :supplier, :at, :listing
  # def price(product, options = {})
  #   company = Entity.of_company
  #   filter = {
  #     :variant_id => product.variant_id
  #   }
  #   # request for an existing price between dates according to filter conditions
  #   prices = self.actives_at(options[:at] || Time.now).where(filter)
  #   # request return no prices, we create a price
  #   if prices.count.zero?
  #     # prices = [self.create!({:tax_id => Tax.first.id, :pretax_amount => filter[:pretax_amount], :amount => filter[:amount]}.merge(filter))]
  #     # calling private method for creating a price for given product (Product or ProductNatureVariant) with given options
  #     prices = new_price(product, options)
  #     return prices
  #   end
  #   # request return at least one price, we return the first
  #   if prices.count >= 1
  #     return prices.first
  #   else
  #     #Rails.logger.warn("#{prices.count} price found for #{options}")
  #     return nil
  #   end
  # end

  # private

  # def new_thread
  #   self.usage + ":" + self.indicator_name.to_s + ":" + Time.now.to_i.to_s(36) + ":" + rand(36 ** 16).to_s(36)
  # end

  # # Create a price with given parameters
  # def new_price(product, options = {})
  #   computed_at = options[:at] || Time.now
  #   price = nil
  #   tax = options[:tax] || Tax.first
  #   # Assigned price
  #   pretax_amount = if options[:pretax_amount]
  #                     options[:pretax_amount].to_d
  #                   elsif options[:amount]
  #                     tax.pretax_amount_of(options[:amount])
  #                   else
  #                     raise StandardError.new("No amounts found, at least amount or pretax_amount must be given to create a price")
  #                   end
  #   amount = tax.amount_of(pretax_amount)
  #   # Amount choice
  #   amount = (self.all_taxes_included ? amount : pretax_amount)
  #   if product.is_a? Product
  #     price = self.create!(:variant_id => product.variant_id, :started_at => computed_at, :amount => amount.round(2), :tax_id => tax.id, :all_taxes_included => self.all_taxes_included)
  #   elsif product.is_a? ProductNatureVariant
  #     price = self.create!(:variant_id => product.id, :started_at => computed_at, :amount => amount.round(2), :tax_id => tax.id, :all_taxes_included => self.all_taxes_included)
  #   else
  #     raise ArgumentError.new("The product argument must be a Product or a ProductNatureVariant not a #{product.class.name}")
  #   end
  #   # elsif self.calculation?
  #   # price = // Formula

  #   return price
  # end

end
