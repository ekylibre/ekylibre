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
# == Table: product_nature_variants
#
#  active               :boolean          default(FALSE), not null
#  category_id          :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  derivative_of        :string
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string
#  nature_id            :integer          not null
#  number               :string
#  picture_content_type :string
#  picture_file_name    :string
#  picture_file_size    :integer
#  picture_updated_at   :datetime
#  reference_name       :string
#  unit_name            :string           not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variety              :string           not null
#

class ProductNatureVariant < Ekylibre::Record::Base
  include Attachable
  enumerize :variety,       in: Nomen::Varieties.all
  enumerize :derivative_of, in: Nomen::Varieties.all
  belongs_to :nature, class_name: 'ProductNature', inverse_of: :variants
  belongs_to :category, class_name: 'ProductNatureCategory', inverse_of: :variants
  has_many :catalog_items, foreign_key: :variant_id, dependent: :destroy
  has_many :products, foreign_key: :variant_id
  has_many :purchase_items, foreign_key: :variant_id, inverse_of: :variant
  has_many :readings, class_name: 'ProductNatureVariantReading', foreign_key: :variant_id, inverse_of: :variant
  has_picture

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :picture_updated_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_inclusion_of :active, in: [true, false]
  validates_presence_of :category, :nature, :unit_name, :variety
  # ]VALIDATORS]
  validates_length_of :derivative_of, :variety, allow_nil: true, maximum: 120
  validates_attachment_content_type :picture, content_type: /image/

  alias_attribute :commercial_name, :name

  delegate :able_to?, :able_to_each?, :has_indicator?, :matching_model, :indicators, :population_frozen?, :population_modulo, :frozen_indicators, :frozen_indicators_list, :variable_indicators, :variable_indicators_list, :linkage_points, :of_expression, :population_counting_unitary?, :whole_indicators_list, :whole_indicators, :individual_indicators_list, :individual_indicators, to: :nature
  delegate :variety, :derivative_of, :name, to: :nature, prefix: true
  delegate :depreciable?, :depreciation_rate, :deliverable?, :purchasable?, :saleable?, :subscribing?, :fixed_asset_depreciation_method, :fixed_asset_depreciation_percentage, :fixed_asset_account, :fixed_asset_allocation_account, :fixed_asset_expenses_account, :product_account, :charge_account, :stock_account, to: :category

  accepts_nested_attributes_for :products, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :readings, reject_if: proc { |params| params['measure_value_value'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :catalog_items, reject_if: :all_blank, allow_destroy: true
  # acts_as_numbered

  scope :availables, -> { where(nature_id: ProductNature.availables).order(:name) }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :purchaseables, -> { joins(:nature).merge(ProductNature.purchaseables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :stockables_or_depreciables, -> { joins(:nature).merge(ProductNature.stockables_or_depreciables).order(:name) }
  scope :of_variety, proc { |*varieties|
    where(variety: varieties.collect { |v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, proc { |*varieties|
    where(derivative_of: varieties.collect { |v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :can, proc { |*abilities|
    # where(nature_id: ProductNature.can(*abilities))
    of_expression(abilities.map { |a| "can #{a}" }.join(' or '))
  }
  scope :can_each, proc { |*abilities|
    # where(nature_id: ProductNature.can_each(*abilities))
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  }
  scope :of_working_set, lambda { |working_set|
    if item = Nomen::WorkingSets.find(working_set)
      of_expression(item.expression)
    else
      fail StandardError, "#{working_set.inspect} is not in Nomen::WorkingSets nomenclature"
    end
  }

  scope :of_expression, lambda { |expression|
    joins(:nature).where(WorkingSet.to_sql(expression, default: :product_nature_variants, abilities: :product_natures, indicators: :product_natures))
  }

  scope :of_natures, lambda { |*natures|
    natures.flatten!
    for nature in natures
      fail ArgumentError.new("Expected Product Nature, got #{nature.class.name}:#{nature.inspect}") unless nature.is_a?(ProductNature)
    end
    where("#{ProductNatureVariant.table_name}.nature_id IN (?)", natures.map(&:id))
  }

  scope :of_categories, lambda { |*categories|
    categories.flatten!
    for category in categories
      fail ArgumentError.new("Expected Product Nature Category, got #{category.class.name}:#{category.inspect}") unless category.is_a?(ProductNatureCategory)
    end
    where("#{ProductNatureVariant.table_name}.category_id IN (?)", categories.map(&:id))
  }

  scope :of_category, ->(category) { where(category: category) }

  protect(on: :destroy) do
    products.any?
  end

  before_validation on: :create do
    if self.nature
      self.category_id = self.nature.category_id
      self.nature_name ||= self.nature.name
      # self.variable_indicators ||= self.nature.indicators
      self.name ||= self.nature_name
      self.variety ||= self.nature.variety
      if derivative_of.blank? && self.nature.derivative_of
        self.derivative_of ||= self.nature.derivative_of
      end
    end
  end

  validate do
    if self.nature
      unless Nomen::Varieties.all(nature_variety).include?(self.variety.to_s)
        logger.debug "#{nature_variety}#{Nomen::Varieties.all(nature_variety)} not include #{self.variety.inspect}"
        errors.add(:variety, :invalid)
      end
      if self.derivative_of
        unless Nomen::Varieties.all(nature_derivative_of).include?(self.derivative_of.to_s)
          errors.add(:derivative_of, :invalid)
        end
      end
    end
  end

  # add animals to new variant
  def add_products(products, options = {})
    Intervention.write(:product_evolution, options) do |i|
      i.cast :variant, self, as: 'product_evolution-variant'
      products.each do |p|
        product = (p.is_a?(Product) ? p : Product.find(p))
        member = i.cast :product, product, as: 'product_evolution-target'
        i.variant_cast :variant, member
      end
    end
  end

  # Measure a product for a given indicator
  def read!(indicator, value, _options = {})
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicators[indicator]
      fail ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    reading = readings.find_or_initialize_by(indicator_name: indicator.name)
    reading.value = value
    reading.save!
    reading
  end

  # Return the reading
  def reading(indicator)
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicators[indicator]
      fail ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    readings.find_by(indicator_name: indicator.name)
  end

  # Returns the direct value of an indicator of variant
  def get(indicator)
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicators[indicator]
      fail ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    if reading = reading(indicator.name)
      return reading.value
    elsif indicator.datatype == :measure
      return 0.0.in(indicator.unit)
    elsif indicator.datatype == :decimal
      return 0.0
    end
    nil
  end

  # check if a variant has an indicator which is frozen or not
  def has_frozen_indicator?(indicator)
    if indicator.is_a?(Nomen::Item)
      return frozen_indicators.include?(indicator)
    else
      return frozen_indicators_list.include?(indicator)
    end
  end

  # Returns a list of couple indicator/unit usable for the given variant
  # The result is only based on measure indicators
  def quantifiers
    list = []
    indicators.each do |indicator|
      next unless indicator.gathering == :proportional_to_population
      if indicator.datatype == :measure
        Measure.siblings(indicator.unit).each do |unit_name|
          list << "#{indicator.name}/#{unit_name}"
        end
      elsif indicator.datatype == :integer || indicator.datatype == :decimal
        list << indicator.name.to_s
      end
    end
    variety = Nomen::Varieties.find(self.variety)
    # Specials indicators
    if variety <= :product_group
      list << 'members_count' unless list.include?('members_count/unity')
      if variety <= :animal_group
        list << 'members_livestock_unit' unless list.include?('members_livestock_unit/unity')
      end
      list << 'members_population' unless list.include?('members_population/unity')
    end
    list
  end

  # Returns a list of quantifier
  def unified_quantifiers(options = {})
    list = quantifiers.map do |quantifier|
      pair = quantifier.split('/')
      indicator = Nomen::Indicators.find(pair.first)
      unit = (pair.second.blank? ? nil : Nomen::Units.find(pair.second))
      hash = { indicator: { name: indicator.name, human_name: indicator.human_name } }
      hash[:unit] = if unit
                      { name: unit.name, symbol: unit.symbol, human_name: unit.human_name }
                    elsif indicator.name =~ /^members\_/
                      unit = Nomen::Units.find(:unity)
                      { name: '', symbol: unit.symbol, human_name: unit.human_name }
                    else
                      { name: '', symbol: unit_name, human_name: unit_name }
                     end
      hash
    end

    # Add population
    if options[:population]
      indicator = Nomen::Indicators[:population]
      list << { indicator: { name: indicator.name, human_name: indicator.human_name }, unit: { name: '', symbol: unit_name, human_name: unit_name } }
    end

    # Add working duration (intervention durations)
    if options[:working_duration]
      for unit in Nomen::Units.where(dimension: :time)
        list << { indicator: { name: :working_duration, human_name: :working_duration.tl }, unit: { name: unit.name, symbol: unit.symbol, human_name: unit.human_name } }
      end
    end

    list
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :reading is true, it returns the ProductNatureVariantReading record
  # if option :interpolate is true, it returns the interpolated value
  # :interpolate and :reading options are incompatible
  def method_missing(method_name, *args)
    return super unless Nomen::Indicators.items[method_name]
    get(method_name)
  end

  def generate(*args)
    options = args.extract_options!
    product_name = args.shift || options[:name]
    born_at = args.shift || options[:born_at]
    default_storage = args.shift || options[:default_storage]

    product_model = nature.matching_model

    product_model.create!(variant: self, name: product_name + ' ' + born_at.l, initial_owner: Entity.of_company, initial_born_at: born_at, default_storage: default_storage)
  end

  # Returns last purchase item for the variant
  # and a given supplier if any, or nil if there's
  # no purchase item matching criterias
  def last_purchase_item_for(supplier = nil)
    return purchase_items.last unless supplier.present?
    purchase_items
      .joins(:purchase)
      .where('purchases.supplier_id = ?', Entity.find(supplier).id)
      .last
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  class << self
    # # Returns indicators for a set of product
    # def indicator(name, options = {})
    #   created_at = options[:at] || Time.now
    #   ProductNatureVariantReading.where("id IN (SELECT p1.id FROM #{self.indicator_table_name(name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(name)} AS p2 ON (p1.variant_id = p2.variant_id AND (p1.created_at < p2.created_at OR (p1.created_at = p2.created_at AND p1.id < p2.id)) AND p2.created_at <= ?) WHERE p1.created_at <= ? AND p1.variant_id IN (?) AND p2 IS NULL)", created_at, created_at, self.pluck(:id))
    # end

    # Find or import variant from nomenclature with given attributes
    # variety and derivative_of only are accepted for now
    def find_or_import!(variety, options = {})
      variants = of_variety(variety)
      if derivative_of = options[:derivative_of]
        variants = variants.derivative_of(derivative_of)
      end
      if variants.empty?
        # Flatten variants for search
        nomenclature = Nomen::ProductNatureVariants.list.collect do |item|
          nature = Nomen::ProductNatures[item.nature]
          h = { reference_name: item.name, variety: Nomen::Varieties[item.variety || nature.variety] } # , nature: nature
          if d = Nomen::Varieties[item.derivative_of || nature.derivative_of]
            h[:derivative_of] = d
          end
          h
        end
        # Filter and imports
        filtereds = nomenclature.select do |item|
          item[:variety].include?(variety) &&
          ((derivative_of && item[:derivative_of] && item[:derivative_of].include?(derivative_of)) || (derivative_of.blank? && item[:derivative_of].blank?))
        end
        filtereds.each do |item|
          import_from_nomenclature(item[:reference_name])
        end
      end
      variants.reload
    end

    # Load a product nature variant from product nature variant nomenclature
    def import_from_nomenclature(reference_name, force = false)
      unless item = Nomen::ProductNatureVariants[reference_name]
        fail ArgumentError, "The product_nature_variant #{reference_name.inspect} is not known"
      end
      unless nature_item = Nomen::ProductNatures[item.nature]
        fail ArgumentError, "The nature of the product_nature_variant #{item.nature.inspect} is not known"
      end
      unless !force && variant = ProductNatureVariant.find_by(reference_name: reference_name.to_s)
        attributes = {
          name: item.human_name,
          active: true,
          nature: ProductNature.import_from_nomenclature(item.nature),
          reference_name: item.name,
          unit_name: I18n.translate("nomenclatures.product_nature_variants.choices.unit_name.#{item.unit_name}"),
          # :frozen_indicators => item.frozen_indicators_values.to_s,
          variety: item.variety || nil,
          derivative_of: item.derivative_of || nil
        }
        variant = new(attributes)
        unless variant.save
          fail "Cannot import variant #{reference_name.inspect}: #{variant.errors.full_messages.join(', ')}"
        end

      end

      unless item.frozen_indicators_values.to_s.blank?
        # create frozen indicator for each pair indicator, value ":population => 1unity"
        item.frozen_indicators_values.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
          .collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each do |i|
          variant.read!(i.first.strip.downcase.to_sym, i.second)
        end
      end

      variant
    end
  end
end
