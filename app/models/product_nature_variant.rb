# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  active                    :boolean          default(FALSE), not null
#  category_id               :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  france_maaid              :string
#  gtin                      :string
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  name                      :string
#  nature_id                 :integer          not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  reference_name            :string
#  stock_account_id          :integer
#  stock_movement_account_id :integer
#  unit_name                 :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variety                   :string           not null
#  work_number               :string
#

class ProductNatureVariant < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :number
  refers_to :variety
  refers_to :derivative_of, class_name: 'Variety'
  belongs_to :nature, class_name: 'ProductNature', inverse_of: :variants
  belongs_to :category, class_name: 'ProductNatureCategory', inverse_of: :variants
  has_many :catalog_items, foreign_key: :variant_id, dependent: :destroy

  has_many :root_components, -> { where(parent: nil) }, class_name: 'ProductNatureVariantComponent', dependent: :destroy, inverse_of: :product_nature_variant, foreign_key: :product_nature_variant_id
  has_many :components, class_name: 'ProductNatureVariantComponent', dependent: :destroy, inverse_of: :product_nature_variant, foreign_key: :product_nature_variant_id

  has_many :part_product_nature_variant_id, class_name: 'ProductNatureVariantComponent'

  belongs_to :stock_movement_account, class_name: 'Account'
  belongs_to :stock_account, class_name: 'Account'

  has_many :contract_items, foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :reception_items, class_name: 'ReceptionItem', foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :shipment_items, class_name: 'ShipmentItem', foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :products, foreign_key: :variant_id, dependent: :restrict_with_exception
  has_many :members, class_name: 'Product', foreign_key: :member_variant_id, dependent: :restrict_with_exception
  has_many :purchase_items, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_exception
  has_many :sale_items, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_exception
  has_many :journal_entry_items, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_exception
  has_many :readings, class_name: 'ProductNatureVariantReading', foreign_key: :variant_id, inverse_of: :variant
  has_many :phases, class_name: 'ProductPhase', foreign_key: :variant_id, inverse_of: :variant
  has_picture

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, inclusion: { in: [true, false] }
  validates :france_maaid, :gtin, :name, :picture_content_type, :picture_file_name, :reference_name, :work_number, length: { maximum: 500 }, allow_blank: true
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :picture_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :picture_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :unit_name, presence: true, length: { maximum: 500 }
  validates :category, :nature, :variety, presence: true
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 60 }
  validates :number, uniqueness: true
  validates :derivative_of, :variety, length: { allow_nil: true, maximum: 120 }
  validates :gtin, length: { allow_nil: true, maximum: 14 }
  validates_attachment_content_type :picture, content_type: /image/

  alias_attribute :commercial_name, :name

  delegate :able_to?, :identifiable?, :able_to_each?, :has_indicator?, :matching_model, :indicators, :population_frozen?, :population_modulo, :frozen_indicators, :frozen_indicators_list, :variable_indicators, :variable_indicators_list, :linkage_points, :of_expression, :population_counting_unitary?, :whole_indicators_list, :whole_indicators, :individual_indicators_list, :individual_indicators, to: :nature
  delegate :variety, :derivative_of, :name, to: :nature, prefix: true
  delegate :depreciable?, :depreciation_rate, :deliverable?, :purchasable?, :saleable?, :storable?, :subscribing?, :fixed_asset_depreciation_method, :fixed_asset_depreciation_percentage, :fixed_asset_account, :fixed_asset_allocation_account, :fixed_asset_expenses_account, :product_account, :charge_account, to: :category

  accepts_nested_attributes_for :products, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :components, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :readings, reject_if: proc { |params| params['measure_value_value'].blank? && params['integer_value'].blank? && params['boolean_value'].blank? && params['decimal_value'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :catalog_items, reject_if: :all_blank, allow_destroy: true
  validates_associated :components

  scope :availables, -> { where(nature_id: ProductNature.availables).order(:name) }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :purchaseables, -> { joins(:nature).merge(ProductNature.purchaseables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :stockables_or_depreciables, -> { joins(:nature).merge(ProductNature.stockables_or_depreciables).order(:name) }
  scope :depreciables, -> { joins(:nature).merge(ProductNature.depreciables).order(:name) }
  scope :identifiables, -> { where(nature: ProductNature.identifiables) }
  scope :services, -> { where(nature: ProductNature.services) }
  scope :tools, -> { where(nature: ProductNature.tools) }

  scope :purchaseables_stockables_or_depreciables, -> { ProductNatureVariant.purchaseables.merge(ProductNatureVariant.stockables_or_depreciables) }
  scope :purchaseables_services, -> { ProductNatureVariant.purchaseables.merge(ProductNatureVariant.services) }

  scope :derivative_of, proc { |*varieties| of_derivative_of(*varieties) }

  scope :can, proc { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' or '))
  }
  scope :can_each, proc { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  }
  scope :of_working_set, lambda { |working_set|
    if item = Nomen::WorkingSet.find(working_set)
      of_expression(item.expression)
    else
      raise StandardError, "#{working_set.inspect} is not in Nomen::WorkingSet nomenclature"
    end
  }

  scope :of_expression, lambda { |expression|
    joins(:nature).where(WorkingSet.to_sql(expression, default: :product_nature_variants, abilities: :product_natures, indicators: :product_natures))
  }

  scope :of_natures, ->(*natures) { where(nature_id: natures) }

  scope :of_categories, ->(*categories) { where(category_id: categories) }

  scope :of_category, ->(category) { where(category: category) }

  protect(on: :destroy) do
    products.any? || sale_items.any? || purchase_items.any? ||
      reception_items.any? || shipment_items.any? || phases.any?
  end

  before_validation on: :create do
    if ProductNatureVariant.any?
      self.category = nature.category if nature
      if category
        num = ProductNatureVariant.order('number::INTEGER DESC').first.number.to_i.to_s.rjust(6, '0').succ
        if category.storable?
          while Account.where(number: [category.stock_movement_account.number + num, category.stock_account.number + num]).any? || ProductNatureVariant.where(number: num).any?
            num.succ!
          end
        end
        self.number = num
      end
    else
      self.number = '000001'
    end
  end

  before_validation do # on: :create
    if nature
      self.category_id = nature.category_id
      self.nature_name ||= nature.name
      # self.variable_indicators ||= self.nature.indicators
      self.name ||= self.nature_name
      self.variety ||= nature.variety
      if derivative_of.blank? && nature.derivative_of
        self.derivative_of ||= nature.derivative_of
      end
      if storable?
        self.stock_account ||= create_unique_account(:stock)
        self.stock_movement_account ||= create_unique_account(:stock_movement)
      end
    end
  end

  validate do
    if nature
      nv = Nomen::Variety.find(nature_variety)
      unless nv >= self.variety
        logger.debug "#{nature_variety}#{Nomen::Variety.all(nature_variety)} not include #{self.variety.inspect}"
        errors.add(:variety, :is, thing: nv.human_name)
      end
      if Nomen::Variety.find(nature_derivative_of)
        if self.derivative_of
          unless Nomen::Variety.find(nature_derivative_of) >= self.derivative_of
            errors.add(:derivative_of, :invalid)
          end
        else
          errors.add(:derivative_of, :blank)
        end
      end
      # if storable?
      #  unless self.stock_account
      #    errors.add(:stock_account, :not_defined)
      #  end
      # unless self.stock_movement_account
      #    errors.add(:stock_movement_account, :not_defined)
      #  end
      # end
    end
    if variety && products.any?
      if products.detect { |p| Nomen::Variety.find(p.variety) > variety }
        errors.add(:variety, :invalid)
      end
    end
    if derivative_of && products.any?
      if products.detect { |p| p.derivative_of? && Nomen::Variety.find(p.derivative_of) > derivative_of }
        errors.add(:derivative_of, :invalid)
      end
    end
  end

  # create unique account for stock management in accountancy
  def create_unique_account(mode = :stock)
    account_key = mode.to_s + '_account'

    category_account = category.send(account_key)
    unless category_account
      # We want to notice => raise.
      raise "Account '#{account_key}' is not configured on category of #{self.name.inspect} variant. You have to check category first"
    end

    options = {}
    options[:number] = category_account.number + number[-6, 6].rjust(6)
    options[:name] = category_account.name + ' [' + self.name + ']'
    options[:label] = options[:number] + ' - ' + options[:name]
    options[:usages] = category_account.usages

    Account.create!(options)
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
  def read!(indicator, value)
    unless indicator.is_a?(Nomen::Item)
      indicator = Nomen::Indicator.find(indicator)
      unless indicator
        raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
      end
    end
    reading = readings.find_or_initialize_by(indicator_name: indicator.name)
    reading.value = value
    reading.save!
    reading
  end

  # Return the reading
  def reading(indicator)
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicator[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
    end
    readings.find_by(indicator_name: indicator.name)
  end

  # Returns the direct value of an indicator of variant
  def get(indicator, _options = {})
    unless indicator.is_a?(Nomen::Item) || indicator = Nomen::Indicator[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicator.all.sort.to_sentence}."
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
      frozen_indicators.include?(indicator)
    else
      frozen_indicators_list.include?(indicator)
    end
  end

  # Returns item from default catalog for given usage
  def default_catalog_item(usage)
    catalog = Catalog.by_default!(usage)
    catalog.items.find_by(variant: self)
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
    variety = Nomen::Variety.find(self.variety)
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
      indicator = Nomen::Indicator.find(pair.first)
      unit = (pair.second.blank? ? nil : Nomen::Unit.find(pair.second))
      hash = { indicator: { name: indicator.name, human_name: indicator.human_name } }
      hash[:unit] = if unit
                      { name: unit.name, symbol: unit.symbol, human_name: unit.human_name }
                    elsif indicator.name =~ /^members\_/
                      unit = Nomen::Unit.find(:unity)
                      { name: '', symbol: unit.symbol, human_name: unit.human_name }
                    else
                      { name: '', symbol: unit_name, human_name: unit_name }
                    end
      hash
    end

    # Add population
    if options[:population]
      # indicator = Nomen::Indicator[:population]
      list << { indicator: { name: :population, human_name: Product.human_attribute_name(:population) }, unit: { name: '', symbol: unit_name, human_name: unit_name } }
    end

    # Add working duration (intervention durations)
    if options[:working_duration]
      Nomen::Unit.where(dimension: :time).find_each do |unit|
        list << { indicator: { name: :working_duration, human_name: :working_duration.tl }, unit: { name: unit.name, symbol: unit.symbol, human_name: unit.human_name } }
      end
    end

    list
  end

  def contractual_prices
    contract_items
      .pluck(:contract_id, :unit_pretax_amount)
      .to_h
      .map { |contract_id, price| [Contract.find(contract_id), price] }
      .to_h
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :reading is true, it returns the ProductNatureVariantReading record
  # if option :interpolate is true, it returns the interpolated value
  # :interpolate and :reading options are incompatible
  def method_missing(method_name, *args)
    return super unless Nomen::Indicator.items[method_name]
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

  # Shortcut for creating a new product of the variant
  def create_product!(attributes = {})
    attributes = product_params(attributes)
    matching_model.create!(attributes.merge(variant: self))
  end

  def create_product(attributes = {})
    attributes = product_params(attributes)
    matching_model.create(attributes.merge(variant: self))
  end

  def product_params(attributes = {})
    attributes[:initial_owner] ||= Entity.of_company
    attributes[:initial_born_at] ||= Time.zone.now
    attributes[:born_at] ||= attributes[:initial_born_at]
    attributes[:name] ||= "#{name} (#{attributes[:initial_born_at].to_date.l})"
    attributes
  end

  def take(quantity)
    products.mine.each_with_object({}) do |product, result|
      reminder = quantity - result.values.sum
      result[product] = [product.population, reminder].min if reminder > 0
      result
    end
  end

  def take!(quantity)
    raise 'errors.not_enough'.t if take(quantity).values.sum < quantity
  end

  # Returns last purchase item for the variant
  # and a given supplier if any, or nil if there's
  # no purchase item matching criterias
  def last_purchase_item_for(supplier = nil)
    return purchase_items.last if supplier.blank?
    purchase_items
      .joins(:purchase)
      .where('purchases.supplier_id = ?', Entity.find(supplier).id)
      .last
  end

  # Return current stock of all products link to the variant
  def current_stock
    products
      .select { |product| product.dead_at.nil? || product.dead_at >= Time.now }
      .map(&:population)
      .compact
      .sum
      .to_f
  end

  # Return current quantity of all products link to the variant currently ordered or invoiced but not delivered
  def current_outgoing_stock_ordered_not_delivered
    undelivereds = sale_items.includes(:sale).map do |si|
      undelivered = 0
      variants_in_parcel_in_sale = ShipmentItem.where(parcel_id: si.sale.parcels.select(:id), variant: self)
      variants_in_transit_parcel_in_sale = ShipmentItem.where(parcel_id: si.sale.parcels.where.not(state: %i[given draft]).select(:id), variant: self)
      delivered_variants_in_parcel_in_sale = ShipmentItem.where(parcel_id: si.sale.parcels.where(state: :given).select(:id), variant: self)

      undelivered = si.quantity if variants_in_parcel_in_sale.none? && !si.sale.draft? && !si.sale.refused? && !si.sale.aborted?
      undelivered = [undelivered, si.quantity - delivered_variants_in_parcel_in_sale.sum(:population)].max if variants_in_parcel_in_sale.present?
      sale_not_canceled = (si.sale.draft? || si.sale.estimate? || si.sale.order? || si.sale.invoice?)
      undelivered = [undelivered, variants_in_transit_parcel_in_sale.sum(:population)].max if sale_not_canceled && variants_in_transit_parcel_in_sale.present?

      undelivered
    end

    undelivereds += shipment_items.joins(:shipment).where.not(parcels: { state: %i[given draft] }).where(parcels: { sale_id: nil, nature: :outgoing }).pluck(:population)

    undelivereds.compact.sum
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  class << self
    # Returns some nomenclature items are available to be imported, e.g. not
    # already imported
    def any_reference_available?
      Nomen::ProductNatureVariant.without(ProductNatureVariant.pluck(:reference_name).uniq).any?
    end

    # Find or import variant from nomenclature with given attributes
    # variety and derivative_of only are accepted for now
    def find_or_import!(variety, options = {})
      variants = of_variety(variety)
      if derivative_of = options[:derivative_of]
        variants = variants.derivative_of(derivative_of)
      end
      if variants.empty?
        # Filter and imports
        filtereds = flattened_nomenclature.select do |item|
          item.variety >= variety &&
            ((derivative_of && item.derivative_of && item.derivative_of >= derivative_of) || (derivative_of.blank? && item.derivative_of.blank?))
        end
        filtereds.each do |item|
          import_from_nomenclature(item.name)
        end
      end
      variants.reload
    end

    ItemStruct = Struct.new(:name, :variety, :derivative_of, :abilities_list, :indicators, :frozen_indicators, :variable_indicators)

    # Returns core attributes of nomenclature merge with nature if necessary
    # name, variety, derivative_od, abilities
    def flattened_nomenclature
      @flattened_nomenclature ||= Nomen::ProductNatureVariant.list.collect do |item|
        nature = Nomen::ProductNature[item.nature]
        f = (nature.frozen_indicators || []).map(&:to_sym)
        v = (nature.variable_indicators || []).map(&:to_sym)
        ItemStruct.new(
          item.name,
          Nomen::Variety.find(item.variety || nature.variety),
          Nomen::Variety.find(item.derivative_of || nature.derivative_of),
          WorkingSet::AbilityArray.load(nature.abilities),
          f + v, f, v
        )
      end
    end

    # Lists ProductNatureVariant::Item which match given expression
    # Fully compatible with WSQL
    def items_of_expression(expression)
      flattened_nomenclature.select do |item|
        WorkingSet.check_record(expression, item)
      end
    end

    # Load a product nature variant from product nature variant nomenclature
    def import_from_nomenclature(reference_name, force = false)
      unless item = Nomen::ProductNatureVariant[reference_name]
        raise ArgumentError, "The product_nature_variant #{reference_name.inspect} is not known"
      end
      unless nature_item = Nomen::ProductNature[item.nature]
        raise ArgumentError, "The nature of the product_nature_variant #{item.nature.inspect} is not known"
      end
      unless !force && (variant = ProductNatureVariant.find_by(reference_name: reference_name.to_s))
        variant = new(
          name: item.human_name,
          active: true,
          nature: ProductNature.import_from_nomenclature(item.nature),
          reference_name: item.name,
          unit_name: I18n.translate("nomenclatures.product_nature_variants.choices.unit_name.#{item.unit_name}"),
          # :frozen_indicators => item.frozen_indicators_values.to_s,
          variety: item.variety || nil,
          derivative_of: item.derivative_of || nil
        )
        unless variant.save
          raise "Cannot import variant #{reference_name.inspect}: #{variant.errors.full_messages.join(', ')}"
        end
      end

      if item.frozen_indicators_values.to_s.present?
        # create frozen indicator for each pair indicator, value ":population => 1unity"
        item.frozen_indicators_values.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
            .collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each do |i|
          indicator_name = i.first.strip.downcase.to_sym
          next unless variant.has_indicator? indicator_name
          variant.read!(indicator_name, i.second)
        end
      end

      variant
    end

    def load_defaults(_options = {})
      Nomen::ProductNatureVariant.all.flatten.collect do |p|
        import_from_nomenclature(p.to_s)
      end
    end
  end
end
