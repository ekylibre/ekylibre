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
# == Table: inventory_items
#
#  actual_population        :decimal(19, 4)   not null
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  expected_population      :decimal(19, 4)   not null
#  id                       :integer          not null, primary key
#  inventory_id             :integer          not null
#  lock_version             :integer          default(0), not null
#  product_id               :integer          not null
#  product_movement_id      :integer
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#

class InventoryItem < Ekylibre::Record::Base
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

  delegate :name, :unit_name, :population_counting_unitary?, to: :product
  delegate :reflected?, :achieved_at, to: :inventory
  delegate :storable?, to: :variant
  delegate :currency, to: :inventory, prefix: true

  before_validation do
    self.actual_population = expected_population if population_counting_unitary?
    self.currency = inventory_currency if inventory
    if variant
      catalog_item = variant.catalog_items.of_usage(:stock)
      if catalog_item.any? && catalog_item.first.pretax_amount != 0.0
        self.unit_pretax_stock_amount = catalog_item.first.pretax_amount
      end
    end
  end

  before_save :compute_average_cost_amount
  before_destroy :compute_rollback_average_cost_amount

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

  protected

  def compute_average_cost_amount
    if inventory.accounted_at.nil?
      many_inventory_items = inventory.items.group_by { |item| item.variant.id }
      many_inventory_items = many_inventory_items.to_a
      many_inventory_items.each do |items|
        items.last.each do |item|
          quantity_entry = item.actual_population
          variant_id = item.variant.id
          ProductNatureVariantValuing.calculate_inventory(quantity_entry, variant_id)
        end
      end
    else
      many_inventory_items = inventory.items.group_by { |item| item.variant.id }
      many_inventory_items = many_inventory_items.to_a
      many_inventory_items.each do |items|
        variant_id = items.first
        valuing_rollback(variant_id)
        items.last.each do |item|
          quantity_entry = item.actual_population
          variant_id = item.variant.id
          ProductNatureVariantValuing.calculate_inventory(quantity_entry, variant_id)
        end
      end
    end
  end

  def compute_rollback_average_cost_amount
    product
    inventories = inventory.items.to_a

    inventories.each do |item|
      product = Product.find(item.product_id).reload
      variant = ProductNatureVariant.find(product.variant_id).reload
      valuing_rollback(variant.id)
    end
  end

  def valuing_rollback(variant_id)
    ProductNatureVariantValuing.rollback_valuing(variant_id)
  end
end
