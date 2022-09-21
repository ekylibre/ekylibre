# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
#  all_taxes_included     :boolean          default(FALSE), not null
#  amount                 :decimal(19, 4)   not null
#  catalog_id             :integer          not null
#  commercial_description :text
#  commercial_name        :string
#  created_at             :datetime         not null
#  creator_id             :integer
#  currency               :string           not null
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string           not null
#  product_id             :integer
#  reference_tax_id       :integer
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer          not null
#

# CatalogItem stores all the prices used in sales and purchases.
class CatalogItem < ApplicationRecord
  attr_readonly :catalog_id
  refers_to :currency
  belongs_to :variant, class_name: 'ProductNatureVariant'
  belongs_to :product, class_name: 'Product'
  belongs_to :reference_tax, class_name: 'Tax'
  belongs_to :catalog
  belongs_to :unit
  belongs_to :sale_item
  belongs_to :purchase_item
  has_one :variant_unit, through: :variant, class_name: 'Unit', foreign_key: :default_unit_id
  has_many :products, through: :variant
  has_many :interventions, through: :products

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :all_taxes_included, inclusion: { in: [true, false] }
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :commercial_description, length: { maximum: 500_000 }, allow_blank: true
  validates :commercial_name, :reference_name, length: { maximum: 500 }, allow_blank: true
  validates :catalog, :currency, :unit, :variant, presence: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(catalog_item) { catalog_item.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :started_at, uniqueness: { scope: %i[catalog_id variant_id unit_id product_id], message: :there_is_already_a_catalog_item_starting_at_the_exact_same_time }
  validates :reference_tax, presence: { if: :all_taxes_included }
  validates :unit, conditioning: true

  # delegate :product_nature_id, :product_nature, to: :template
  delegate :name, to: :variant, prefix: true
  delegate :unit_name, to: :variant
  delegate :usage, :all_taxes_included?, to: :catalog
  delegate :dimension, :of_dimension?, to: :unit

  scope :started_after, ->(date) { where('? < started_at', date).order(:started_at) }
  scope :started_before, ->(date) { where('? > started_at', date).order(:started_at) }

  scope :active_at, ->(date) { where('started_at <= ? AND stopped_at IS NULL OR stopped_at >= ?', date, date).order(:started_at) }

  scope :of_variant, lambda { |variant|
    where(variant: variant)
  }

  scope :of_product, lambda { |product|
    where(product: product)
  }

  scope :of_unit, lambda { |unit|
    where(unit: unit)
  }

  scope :of_base_unit, lambda { |base_unit|
    where(unit_id: Unit.where(base_unit: base_unit).pluck(:id))
  }

  scope :of_dimension_unit, lambda { |dimension_unit|
    where(unit_id: Unit.where(dimension: dimension_unit).pluck(:id))
  }

  scope :of_usage, lambda { |usage|
    joins(:catalog).merge(Catalog.of_usage(usage))
  }

  scope :saleables, lambda {
    joins(variant: :category).where(product_nature_categories: { saleable: true })
  }

  before_validation on: :create do
    self.currency = Preference[:currency] if currency.blank?
  end

  before_validation do
    self.amount = amount.round(4) if amount
    self.name = commercial_name
    self.name = variant_name if commercial_name.blank? && variant
    self.name = product.name if commercial_name.blank? && product
    self.unit ||= variant.guess_conditioning[:unit] if variant
    self.unit ||= product.conditioning_unit if product
    self.variant ||= product.variant if product
    set_stopped_at if catalog && following_items.any?
  end

  before_validation :set_stopped_at

  after_save do
    set_previous_stopped_at if previous_items.any?
    # update interventions with update price
    intervention_ids_to_update = []
    variant.products.each do |product|
      intervention_ids_to_update << product.interventions.where('started_at >= ?', started_at)&.pluck(:id)
    end
    int_ids = intervention_ids_to_update.compact.uniq
    UpdateInterventionCostingsJob.perform_later(int_ids, to_reload: true) if int_ids.any?
  end

  # Find unit_amout in default unit of variant
  def unit_amount_in_target_unit(target_unit)
    unit_amount_with_indicator = { unit_amount: 0.0, indicator: nil, unit: nil }
    o_target_unit = Unit.find_by(reference_name: target_unit.to_s)

    if unit && o_target_unit.dimension == unit.dimension
      converted_amount = UnitComputation.convert_amount(pretax_amount, unit, o_target_unit)
      unit_amount_with_indicator[:unit_amount] = converted_amount.to_d.round(2)
      unit_amount_with_indicator[:indicator] = Unit::STOCK_INDICATOR_PER_DIMENSION[unit.dimension.to_sym]
      unit_amount_with_indicator[:unit] = target_unit
    elsif variant.nature.population_counting == 'decimal'
      o_variant_unit = Onoma::Unit[variant.default_unit.reference_name.to_sym]
      if variant.default_quantity.to_f > 0.0 && o_variant_unit.dimension == o_target_unit.dimension
        coefficient = Measure.new(variant.default_quantity, variant.default_unit.reference_name.to_sym).convert(target_unit.to_sym).to_f
        unit_amount_with_indicator[:unit_amount] = (pretax_amount / coefficient).round(2)
        unit_amount_with_indicator[:indicator] = Unit::STOCK_INDICATOR_PER_DIMENSION[o_variant_unit.dimension.to_sym]
        unit_amount_with_indicator[:unit] = target_unit
      end
      # TODO: manage other case where o_target_unit.dimension != unit.dimension
    end
    unit_amount_with_indicator
  end

  def uncoefficiented_amount
    unit&.coefficient ? (amount / unit.coefficient) : amount
  end

  # Compute a pre-tax amount
  def pretax_amount(into: unit)
    destination_unit = into.is_a?(Unit) ? into : Unit.import_from_lexicon(into)
    raise ArgumentError.new("Unknown unit #{into}") unless destination_unit.present?

    amnt = all_taxes_included && reference_tax ? reference_tax.pretax_amount_of(amount) : amount
    UnitComputation.convert_amount(amnt, unit, destination_unit).round(2)
  end

  alias unit_pretax_amount pretax_amount

  def sibling_items
    if product
      self.class.of_product(product).where(catalog: catalog).of_unit(unit)
    else
      self.class.of_variant(variant).where(catalog: catalog).of_unit(unit)
    end
  end

  def following_items
    sibling_items.started_after(started_at)
  end

  def previous_items
    sibling_items.started_before(started_at)
  end

  class << self
    def import_from_lexicon(reference_name)
      # global case
      if MasterPrice.find_by(reference_name: reference_name)
        item = MasterPrice.find_by(reference_name: reference_name)
        unless variant = ProductNatureVariant.find_by_reference_name(item.reference_article_name)
          variant = ProductNatureVariant.import_from_lexicon(item.reference_article_name)
        end
      # phyto case
      elsif MasterPhytosanitaryPrice.find_by(reference_name: reference_name)
        item = MasterPhytosanitaryPrice.find_by(reference_name: reference_name)
        unless variant = ProductNatureVariant.find_by_france_maaid(item.reference_article_name.to_s)
          variant = ProductNatureVariant.import_from_lexicon(item.reference_article_name.to_s)
        end
      else
        raise ArgumentError.new("The variant price #{reference_name.inspect} is unknown")
      end

      if catalog_item = CatalogItem.find_by(reference_name: reference_name)
        return catalog_item
      end

      unit = Unit.import_from_lexicon(item.reference_packaging_name)
      price = new(
        name: variant.name,
        variant: variant,
        catalog: Catalog.by_default!(item.usage),
        amount: item.unit_pretax_amount,
        currency: Onoma::Currency.find(item.currency) ? item.currency : 'EUR',
        started_at: item.started_on.to_datetime,
        reference_name: item.reference_name,
        unit: unit
      )

      existing_price = CatalogItem.find_by(variant: variant, catalog: Catalog.by_default!(item.usage), started_at: item.started_on.to_datetime, unit: unit)
      # return price with the same attributes (variant, catalog, started_at, unit) if exist
      if existing_price
        price = existing_price
      # save new price
      else
        unless price.save
          raise "Cannot import MasterPrice into CatalogItem #{reference_name.inspect}: #{price.errors.full_messages.join(', ')}"
        end

        price
      end
    end

    def load_defaults(**_options)
      MasterPrice.find_each do |price|
        # TODO : remove this once lexicon data is correct
        next if %w[wire grape potato_plant electricity equipment_rent wheat_harvesting_service running_water vegetal_service].include? price.reference_article_name

        import_from_lexicon(price.reference_name)
      end
    end
  end

  private

    def set_stopped_at
      if catalog && following_items.any?
        following_item = following_items.first
        self.stopped_at = following_item.started_at - 1.minute if id != following_item.id
      end
    end

    def set_previous_stopped_at
      previous_item = previous_items.last
      previous_item.update!(stopped_at: started_at - 1.minute)
    end
end
