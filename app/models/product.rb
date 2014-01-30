# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: products
#
#  address_id               :integer
#  born_at                  :datetime
#  category_id              :integer          not null
#  content_indicator_name   :string(255)
#  content_indicator_unit   :string(255)
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  dead_at                  :datetime
#  default_storage_id       :integer
#  derivative_of            :string(120)
#  description              :text
#  father_id                :integer
#  financial_asset_id       :integer
#  id                       :integer          not null, primary key
#  identification_number    :string(255)
#  initial_arrival_cause    :string(120)
#  initial_container_id     :integer
#  initial_owner_id         :integer
#  initial_population       :decimal(19, 4)   default(0.0)
#  lock_version             :integer          default(0), not null
#  mother_id                :integer
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      not null
#  parent_id                :integer
#  picture_content_type     :string(255)
#  picture_file_name        :string(255)
#  picture_file_size        :integer
#  picture_updated_at       :datetime
#  reservoir                :boolean          not null
#  tracking_id              :integer
#  type                     :string(255)
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer          not null
#  variety                  :string(120)      not null
#  work_number              :string(255)
#


class Product < Ekylibre::Record::Base
  include Versionable
  enumerize :variety, in: Nomen::Varieties.all, predicates: {prefix: true}
  enumerize :derivative_of, in: Nomen::Varieties.all
  enumerize :content_indicator_name, in: Nomen::Indicators.all, predicates: {prefix: true}
  enumerize :content_indicator_unit, in: Nomen::Units.all, predicates: {prefix: true}
  enumerize :initial_arrival_cause, in: [:birth, :housing, :other, :purchase], default: :birth, predicates: {prefix: true}
  belongs_to :address, class_name: "EntityAddress"
  belongs_to :financial_asset
  belongs_to :default_storage, class_name: "Product"
  belongs_to :category, class_name: "ProductNatureCategory"
  belongs_to :content_nature, class_name: "ProductNature"
  belongs_to :parent, class_name: "Product"
  belongs_to :father, class_name: "Product"
  belongs_to :initial_container, class_name: "Product"
  belongs_to :initial_owner, class_name: "Entity"
  # belongs_to :initial_enjoyer, class_name: "Entity"
  belongs_to :mother, class_name: "Product"
  belongs_to :nature, class_name: "ProductNature"
  belongs_to :tracking
  belongs_to :variant, class_name: "ProductNatureVariant"
  has_many :carrier_linkages, class_name: "ProductLinkage", foreign_key: :carried_id
  has_many :enjoyments, class_name: "ProductEnjoyment", foreign_key: :product_id
  has_many :issues, as: :target
  has_many :indicator_data, class_name: "ProductIndicatorDatum", dependent: :destroy, inverse_of: :product
  has_many :intervention_casts, foreign_key: :actor_id, inverse_of: :actor
  has_many :groups, :through => :memberships
  has_many :measurements, class_name: "ProductMeasurement"
  has_many :memberships, class_name: "ProductMembership", foreign_key: :member_id
  has_many :junction_ways, class_name: "ProductJunctionWay"
  has_many :linkages, class_name: "ProductLinkage", foreign_key: :carrier_id
  has_many :localizations, class_name: "ProductLocalization", foreign_key: :product_id
  has_many :ownerships, class_name: "ProductOwnership", foreign_key: :product_id
  has_many :phases, class_name: "ProductPhase"
  has_many :supports, class_name: "ProductionSupport", foreign_key: :storage_id, inverse_of: :storage
  has_many :markers, :through => :supports
  has_many :variants, class_name: "ProductNatureVariant", :through => :phases
  # has_one :birth, class_name: "ProductBirth", inverse_of: :product
  # has_one :death, class_name: "ProductDeath", inverse_of: :product
  has_one :current_phase,        -> { current }, class_name: "ProductPhase",        foreign_key: :product_id
  has_one :current_localization, -> { current }, class_name: "ProductLocalization", foreign_key: :product_id
  has_one :current_ownership,    -> { current }, class_name: "ProductOwnership",    foreign_key: :product_id
  has_one :container, through: :current_localization

  has_attached_file :picture, {
    :url => '/backend/:class/:id/picture/:style',
    :path => ':rails_root/private/:class/:attachment/:id_partition/:style.:extension',
    :styles => {
      :thumb => ["64x64#", :jpg],
      :identity => ["180x180#", :jpg]
      # :large => ["600x600", :jpg]
    }
  }

  scope :members_of, lambda { |group, viewed_at| where("id IN (SELECT member_id FROM #{ProductMembership.table_name} WHERE group_id = ? AND nature = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", group.id, "interior", viewed_at, viewed_at, viewed_at)}
  scope :of_variety, lambda { |*varieties|
    where(variety: varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, lambda { |*varieties|
    where(derivative_of: varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :can, lambda { |*abilities|
    where(nature_id: ProductNature.can(*abilities))
  }
  scope :can_each, lambda { |*abilities|
    where(nature_id: ProductNature.can_each(*abilities))
  }

  scope :of_nature, lambda { |nature|
    where(nature_id: nature.id)
  }
  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :indicate, lambda { |indicator_values, options = {}|
    measured_at = options[:at] || Time.now
    conditions = []
    # TODO Build conditions to filter on indicator_values
    for name, value in indicator_values
      data = ProductIndicatorDatum.of_products(self, name, measured_at).where("#{Nomen::Indicators[name].datatype}_value" => value)
      if data.any?
        conditions << " id IN (" + data.pluck(:product_id).join(", ") + ")"
      end
    end
    where(conditions.join(" AND "))
  }
  scope :not_indicate, lambda { |indicator_values, options = {}|
    measured_at = options[:at] || Time.now
    conditions = []
    # TODO Build conditions to filter on indicator_values
    for name, value in indicator_values
      data = ProductIndicatorDatum.of_products(self, name, measured_at).where("#{Nomen::Indicators[name].datatype}_value" => value)
      if data.any?
        conditions << " id IN (" + data.pluck(:product_id).join(", ") + ")"
      end
    end
    where.not(conditions.join(" AND "))
  }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :production_supports,  -> { where(variety: ["cultivable_zone"]) }
  scope :supporters,  -> { of_variety(:cultivable_zone) }
  scope :availables, -> { where(dead_at: nil).not_indicate(population: 0) }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_numericality_of :content_maximal_quantity, :initial_population, allow_nil: true
  validates_length_of :derivative_of, :initial_arrival_cause, :variety, allow_nil: true, maximum: 120
  validates_length_of :content_indicator_name, :content_indicator_unit, :identification_number, :name, :number, :picture_content_type, :picture_file_name, :work_number, allow_nil: true, maximum: 255
  validates_inclusion_of :reservoir, in: [true, false]
  validates_presence_of :category, :content_maximal_quantity, :name, :nature, :number, :variant, :variety
  #]VALIDATORS]
  validates_presence_of :nature, :variant, :name

  # accepts_nested_attributes_for :birth
  # accepts_nested_attributes_for :death
  accepts_nested_attributes_for :indicator_data, allow_destroy: true, reject_if: lambda { |datum|
    !datum["indicator"] != "population" and datum[ProductIndicatorDatum.value_column(datum["indicator"]).to_s].blank?
  }
  accepts_nested_attributes_for :memberships, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: false
  delegate :serial_number, :producer, to: :tracking
  delegate :name, to: :nature, prefix: true
  delegate :variety, :derivative_of, :name, :nature, to: :variant, prefix: true
  delegate :unit_name, to: :variant
  delegate :subscribing?, :deliverable?, :asset_account, :product_account, :charge_account, :stock_account, to: :nature
  delegate :individual_indicators_list, :whole_indicators_list, :abilities, :abilities_list, :indicators, :indicators_list, :linkage_points, :linkage_points_list, to: :nature

  after_initialize :choose_default_name
  after_create :set_initial_values
  before_validation :set_default_values, on: :create
  before_validation :update_default_values, on: :update

  before_validation do
    if self.variant
      self.nature ||= self.variant_nature
    end
  end

  after_validation do
    self.default_storage ||= self.initial_container
    self.initial_container ||= self.default_storage
  end

  validate do
    if self.nature and self.variant
      if self.variant.nature_id != self.nature_id
        errors.add(:nature_id, :invalid)
      end
    end
    if self.variant
      unless Nomen::Varieties.all(self.variant_variety).include?(self.variety.to_s)
        errors.add(:variety, :invalid)
      end
      if self.derivative_of
        unless Nomen::Varieties.all(self.variant_derivative_of).include?(self.derivative_of.to_s)
          errors.add(:derivative_of, :invalid)
        end
      end
    end
  end

  protect(on: :destroy) do
    self.intervention_casts.any? or self.supports.any? or self.issues.any?
  end

  class << self
    # Auto-cast product to best matching class with type column
    def new_with_cast(*attributes, &block)
      if (h = attributes.first).is_a?(Hash) && !h.nil? && (type = h[:type] || h['type']) && type.length > 0 && (klass = type.constantize) != self
        raise "Can not cast #{self.name} to #{klass.name}" unless klass <= self
        return klass.new(*attributes, &block)
      end
      return new_without_cast(*attributes, &block)
    end
    alias_method_chain :new, :cast

  end

  # TODO: Removes this ASAP
  def deliverable?
    false
  end


  # set initial owner and localization
  def set_initial_values
    # Set population
    # self.is_measured!(:population, self.initial_population)
    # Add first owner on a product
    self.ownerships.create!(owner: self.initial_owner)
    # # Add first enjoyer on a product
    # self.enjoyments.create!(enjoyer: self.initial_enjoyer)
    # Add first localization on a product
    if self.initial_container # and self.initial_arrival_cause
      self.localizations.create!(container: self.initial_container, nature: :interior, arrival_cause: self.initial_arrival_cause || :birth)
    end
    # add first frozen indicator on a product from his variant
    if self.variant
      for datum in self.variant.indicator_data
        self.is_measured!(datum.indicator_name, datum.value, at: :origin)
      end
      self.phases.create!(variant: self.variant)
    end
  end


  # Try to find the best name for the new products
  def choose_default_name
    if self.name.blank?
      if self.variant
        if last = self.variant.products.reorder(id: :desc).first
          self.name = last.name
          array = self.name.split(/\s+/)
          if array.last.match(/^\(+\d+\)+?$/)
            self.name = array[0..-2].join(" ") + " (" + array.last.gsub(/(^\(+|\)+$)/, '').to_i.succ.to_s + ")"
          else
            self.name << " (1)"
          end
        else
          self.name = self.variant_name
        end
      end
      if self.name.blank?
        # By default, choose a random name
        # TODO...
        self.name = Faker::Name.first_name
      end
    end
  end

  # Sets nature and variety from variant
  def set_default_values
    if self.variant
      self.nature    = self.variant.nature
      self.variety ||= self.variant_variety
    end
    if self.nature
      self.category = self.nature.category
    end
  end

  # Update nature and variety and variant from phase
  def update_default_values
    if self.current_phase
      self.nature    = self.current_phase.variant.nature
      self.variety ||= self.current_phase.variant_variety
    end
    if self.nature
      self.category = self.nature.category
    end
  end

  # Returns the matching model for the record
  def matching_model
    return ProductNature.matching_model(self.variety)
  end


  # Returns the price for the product.
  # It's a shortcut for CatalogPrice::give
  def price(options = {})
    return CatalogPrice.price(self, options)
  end

  # Returns an evaluated price (without taxes) for the product in an intervention context
  # options could contains a parameter :at for the datetime of a catalog price
  # unit_price in a purchase context
  # or unit_price in a sale context
  # or unit_price in catalog price
  def evaluated_price(options = {})
    filter = {
      variant_id: self.variant_id
    }
    incoming_item = IncomingDeliveryItem.where(product_id: self.id).first
    incoming_purchase_item = incoming_item.purchase_item if incoming_item
    outgoing_item = OutgoingDeliveryItem.where(product_id: self.id).first
    outgoing_sale_item = outgoing_item.sale_item if outgoing_item

    if incoming_purchase_item
      # search a price in purchase item via incoming item price
      price = incoming_purchase_item.unit_price_amount
    elsif outgoing_sale_item
      # search a price in sale item via outgoing item price
      price = outgoing_sale_item.unit_price_amount
    elsif price_object = CatalogPrice.actives_at(options[:at] || Time.now).where(filter).first
      # search a price in catalog price
      if price_object.all_taxes_included == true
        tax = Tax.find(price_object.reference_tax_id)
        price = tax.pretax_amount_of(price_object.amount)
      else
        price = price_object.amount
      end
    else
      price = nil
    end
    return price
  end


  def dead?
    return !self.death.nil?
  end

  # Returns groups of the product at a given time (or now by default)
  def groups_at(viewed_at = nil)
    ProductGroup.groups_of(self, viewed_at || Time.now)
  end

  # Returns the current contents of the product at a given time (or now by default)
  def contains(content_class = Product, at = Time.now)
    localizations = ProductLocalization.where(container: self).where("started_at <= ?",at)
    if localizations.any?
      object = {}
      for localization in localizations
        object << localization.product if localization.product.is_a(content_class)
      end
      return object
     else
       return nil
    end
  end

  # Returns the current container for the product
  def owner
    if o = self.current_ownership
      return o.owner
    end
    return nil
  end

  # # Returns the current container for the product
  # def container(at = Time.now)
  #   if l = self.localizations.at(at).first
  #     return l.container
  #   end
  #   return self.default_storage
  # end

  def picture_path(style=:original)
    self.picture.path(style)
  end

  # def net_surface_area(*args)
  #   if self.indicators_list.include?(:net_surface_area)
  #     return self.get(:net_surface_area, *args)
  #   elsif self.whole_indicators_list.include?(:shape)
  #     options = args.extract_options!
  #     at = args.shift || options[:at] || Time.now
  #     # TODO Manage InterventionCast ?
  #     return self.shape_area(at: at) rescue 0.0.in_square_meter
  #   end
  #   return 0.0.in_square_meter
  # end

  # def net_surface_area(*args)
  #   unless value = self.get(:net_surface_area, *args)
  #     if self.whole_indicators_list.include?(:shape)
  #       options = args.extract_options!
  #       at = args.shift || options[:at] || Time.now
  #       # TODO Manage InterventionCast ?
  #       value = self.shape_area(at: at) # rescue 0.0.in_square_meter
  #     end
  #   end
  #   return value
  # end

  def area(unit = :hectare, at = Time.now)
    ActiveSupport::Deprecation.warn("Product#area is deprecated. Please use Product#net_surface_area instead.")
    return net_surface_area(at).in(unit)
  end

  def mass(unit = :kilogram, at = Time.now)
    ActiveSupport::Deprecation.warn("Product#mass is deprecated. Please use Product#net_mass instead.")
    return net_mass(at).in(unit)
  end

  def population(*args)
    return self.get(:population, *args) || 0.0
  end


  # Measure a product for a given indicator
  def is_measured!(indicator, value, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    if value.nil?
      raise ArgumentError, "Value must be given"
    end
    options[:at] = Time.new(1, 1, 1, 0, 0, 0, "+00:00") if options[:at] == :origin
    datum = self.indicator_data.build(indicator_name: indicator.name, measured_at: (options[:at] || Time.now), originator: options[:originator])
    datum.value = value
    datum.save!
    return datum
  end

  # Return the indicator datum
  def indicator_datum(indicator, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    measured_at = options[:at] || Time.now
    return self.indicator_data.where(indicator_name: indicator.name).where("measured_at <= ?", measured_at).reorder(measured_at: :desc).first
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :interpolate is true, it returns the interpolated value
  def get(indicator, *args)
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    options = args.extract_options!
    cast_or_time = args.shift || options[:cast] || options[:at] || Time.now
    value = nil
    if cast_or_time.is_a?(Time)
      # Find value
      if options[:interpolate]
        if [:measure, :decimal].include?(indicator.datatype)
          raise NotImplementedError, "Interpolation is not available for now"
        end
        raise StandardError, "Can not use :interpolate option with #{indicator.datatype.inspect} datatype"
      elsif datum = self.indicator_datum(indicator.name, at: cast_or_time)
        value = datum.value
      elsif !options[:default].is_a?(FalseClass)
        if indicator.datatype == :measure
          value = 0.0.in(indicator.unit)
        elsif indicator.datatype == :decimal
          value = 0.0
        end
      end
      # Adjust value
      if value and indicator.gathering and !options[:gathering].is_a?(FalseClass)
        if indicator.gathering == :proportional_to_population
          value *= self.send(:population, at: cast_or_time)
          # @TODO puts method to compute nitrogen,....
        end
      end
    elsif cast_or_time.is_a?(InterventionCast)
      if cast_or_time.actor and cast_or_time.actor.whole_indicators_list.include?(indicator.name.to_sym)
        value = cast_or_time.send(indicator.name)
      elsif cast_or_time.reference.new?
        unless variant = cast_or_time.variant || cast_or_time.reference.variant(cast.intervention)
          raise StandardError, "Need variant to know how to measure it"
        end
        if variant.frozen_indicators.include?(indicator)
          value = variant.get(indicator)
        else
          raise StandardError, "Cannot find a frozen indicator #{indicator.name} for variant"
        end
      elsif datum = self.indicator_datum(indicator.name, at: cast_or_time.intervention.started_at)
        value = datum.value
      else
        raise "What ?"
      end
      # Adjust value
      if value and indicator.gathering and !options[:gathering].is_a?(FalseClass)
        if indicator.gathering == :proportional_to_population
          value *= cast_or_time.population
        end
      end
    else
      raise "Cannot support #{cast_or_time.inspect} parameter"
    end
    return value
  end


  def get!(indicator, *args)
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    unless value = get(indicator, *args)
      raise "Cannot get value of #{indicator.name} for product ##{self.id}"
    end
    return value
  end

  # # Returns indicators for a set of product
  # def self.indicator_data(name, options = {})
  #   measured_at = options[:at] || Time.now
  #   ProductIndicatorDatum.where("id IN (SELECT p1.id FROM #{self.indicator_table_name(name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator = p2.indicator AND (p1.measured_at < p2.measured_at OR (p1.measured_at = p2.measured_at AND p1.id < p2.id)) AND p2.measured_at <= ?) WHERE p1.measured_at <= ? AND p1.product_id IN (?) AND p1.indicator = ? AND p2 IS NULL)", measured_at, measured_at, self.pluck(:id), name)
  # end


  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicators.all.include?(method_name.to_s.gsub(/\!\z/, ''))
      if method_name.to_s =~ /\!\z/
        return get!(method_name.to_s.gsub(/\!\z/, ''), *args)
      else
        return get(method_name, *args)
      end
    end
    return super
  end

  # # Give the indicator table name
  # def self.indicator_table_name(indicator)
  #   ProductIndicatorDatum.table_name
  # end

end
