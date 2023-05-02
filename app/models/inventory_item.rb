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
# == Table: inventory_items
#
#  actual_population        :decimal(19, 4)   not null
#  created_at               :datetime         not null
#  creator_id               :integer(4)
#  currency                 :string
#  expected_population      :decimal(19, 4)   not null
#  id                       :integer(4)       not null, primary key
#  inventory_id             :integer(4)       not null
#  lock_version             :integer(4)       default(0), not null
#  product_id               :integer(4)       not null
#  product_movement_id      :integer(4)
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer(4)
#

class InventoryItem < ApplicationRecord
  belongs_to :inventory, inverse_of: :items
  belongs_to :product
  belongs_to :product_movement, dependent: :destroy
  has_one :variant, class_name: 'ProductNatureVariant', through: :product
  has_one :nature, class_name: 'ProductNature', through: :product
  has_one :category, class_name: 'ProductNatureCategory', through: :product
  has_one :container, through: :product

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :actual_population, :expected_population, :unit_pretax_stock_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :currency, length: { maximum: 500 }, allow_blank: true
  validates :inventory, :product, presence: true
  # ]VALIDATORS]

  scope :of_variant, ->(variant) { joins(:product).merge(Product.of_variant(variant)) }

  delegate :name, :unit_name, :population_counting_unitary?, to: :product, allow_nil: true
  delegate :reflected?, :achieved_at, to: :inventory
  delegate :storable?, to: :variant
  delegate :currency, to: :inventory, prefix: true

  after_initialize do
    # callback are 2 times executed during creating inventory.
    if !persisted? && inventory
      self.actual_population = population_at(achieved_at) if actual_population.present? && actual_population < 0.0
      self.unit_pretax_stock_amount = price_at(achieved_at) if unit_pretax_stock_amount.present? && unit_pretax_stock_amount == 0.0
    end
  end

  before_validation do
    self.actual_population = expected_population if population_counting_unitary?
    if inventory
      self.currency = inventory_currency
      self.actual_population ||= population_at(achieved_at)
      self.unit_pretax_stock_amount ||= price_at(achieved_at)
    else
      self.currency = 'EUR'
      self.actual_population ||= 0.0
      self.unit_pretax_stock_amount ||= 0.0
    end
  end

  after_save do
    if reflected?
      movement = product_movement || build_product_movement
      movement.product = product
      movement.delta = delta
      movement.started_at = achieved_at
      movement.save!
      update_columns(product_movement_id: movement.id)
    elsif product_movement
      ProductMovement.destroy(product_movement)
      update_columns(product_movement_id: nil)
    end
  end

  # Returns the delta population between actual and expectedp populations
  def delta
    actual_population - expected_population
  end

  def actual_pretax_stock_amount
    actual_population * unit_pretax_stock_amount
  end

  def price_at(time)
    if product
      catalog_items = product.variant.catalog_items.of_unit(product.conditioning_unit).active_at(time)
    end
    if catalog_items.any?
      catalog_items.first.pretax_amount
    else
      0.0
    end
  end

  def population_at(time)
    p = product.population(at: time)
    if p && p < 0.0
      0.0
    elsif p && p >= 0.0
      p
    else
      nil
    end
  end
end
