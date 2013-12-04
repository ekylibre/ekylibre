# -*- coding: utf-8 -*-
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
# == Table: products
#
#  address_id               :integer
#  asset_id                 :integer
#  born_at                  :datetime
#  category_id              :integer          not null
#  content_indicator        :string(255)
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
  enumerize :variety, in: Nomen::Varieties.all, predicates: {prefix: true}
  enumerize :derivative_of, in: Nomen::Varieties.all
  enumerize :content_indicator, in: Nomen::Indicators.all, predicates: {prefix: true}
  enumerize :content_indicator_unit, in: Nomen::Units.all, predicates: {prefix: true}
  enumerize :initial_arrival_cause, in: [:birth, :housing, :other, :purchase], default: :birth, :predicates =>{prefix: true}
  belongs_to :asset
  belongs_to :default_storage, class_name: "Product"
  belongs_to :category, class_name: "ProductNatureCategory"
  belongs_to :content_nature, class_name: "ProductNature"
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
  has_many :incidents, class_name: "Incident", :as => :target
  has_many :indicator_data, class_name: "ProductIndicatorDatum", dependent: :destroy
  has_many :intervention_casts, foreign_key: :actor_id, inverse_of: :actor
  has_many :groups, :through => :memberships
  has_many :memberships, class_name: "ProductMembership", foreign_key: :member_id
  has_many :linkages, class_name: "ProductLinkage", foreign_key: :carrier_id
  has_many :localizations, class_name: "ProductLocalization", foreign_key: :product_id
  has_many :ownerships, class_name: "ProductOwnership", foreign_key: :product_id
  has_many :phases, class_name: "ProductPhase"
  has_many :supports, class_name: "ProductionSupport", foreign_key: :storage_id, inverse_of: :storage
  has_many :variants, class_name: "ProductNatureVariant", :through => :phases
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
    where(:variety => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, lambda { |*varieties|
    where(:derivative_of => varieties.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :can, lambda { |*abilities|
    where(:nature_id => ProductNature.can(*abilities))
  }

  scope :of_nature, lambda { |nature|
    where(:nature_id => nature.id)
  }
  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :indicate, lambda { |indicators, options = {}|
    measured_at = options[:at] || Time.now
    conditions = []
    # TODO Build conditions to filter on indicators
    for name, value in indicators
      conditions << " id IN (" + order(:id).indicator(name, at: measured_at).where("#{Nomen::Indicators[name].datatype}_value" => value).pluck(:product_id).join(", ") + ")"
    end
    where(conditions.join(" AND "))
  }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :production_supports,  -> { where(variety: ["cultivable_land_parcel"]) }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_numericality_of :content_maximal_quantity, :initial_population, allow_nil: true
  validates_length_of :derivative_of, :initial_arrival_cause, :variety, allow_nil: true, maximum: 120
  validates_length_of :content_indicator, :content_indicator_unit, :identification_number, :name, :number, :picture_content_type, :picture_file_name, :work_number, allow_nil: true, maximum: 255
  validates_inclusion_of :reservoir, in: [true, false]
  validates_presence_of :category, :content_maximal_quantity, :name, :nature, :number, :variant, :variety
  #]VALIDATORS]
  validates_presence_of :nature, :variant, :name

  accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :indicator_data, allow_destroy: true, reject_if: :all_blank # lambda { |datum| !datum["indicator"] != "population" and datum["#{Nomen::Indicators[datum["indicator"]]}_value"]}
  acts_as_numbered force: false
  delegate :serial_number, :producer, to: :tracking
  delegate :name, to: :nature, prefix: true
  delegate :subscribing?, :deliverable?, to: :nature
  delegate :variety, :derivative_of, :name, to: :variant, prefix: true
  delegate :abilities, :abilities_array, :indicators, :indicators_array, :linkage_points_array, :unit_name, to: :variant
  delegate :asset_account, :product_account, :charge_account, :stock_account, :individual_indicators, :whole_indicators, to: :nature

  after_initialize :choose_default_name
  after_create :set_initial_values
  before_validation :set_default_values, on: :create
  before_validation :update_default_values, on: :update

  after_validation do
    self.default_storage ||= self.initial_container
    self.initial_container ||= self.default_storage
  end

  validate do
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
        self.is_measured!(datum.indicator, datum.value)
      end
      self.phases.create!(variant: self.variant) # , started_at: self.born_at) if self.born_at
    end
  end


  # Try to find the best name for the new products
  def choose_default_name
    if self.new_record? and self.name.blank?
      if self.variant
        if last = self.class.where(:variant_id => self.variant_id).reorder("id DESC").first
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
      else
        # By default, choose a random name
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
      :variant_id => self.variant_id
    }
    incoming_item = IncomingDeliveryItem.where(:product_id => self.id).first
    incoming_purchase_item = incoming_item.purchase_item if incoming_item
    outgoing_item = OutgoingDeliveryItem.where(:product_id => self.id).first
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

  def net_surface_area(at = Time.now)
    if self.whole_indicators.include?(:net_surface_area)
      return self.send(:net_surface_area)
    elsif self.individual_indicators.include?(:net_surface_area)
      return self.send(:net_surface_area) * self.population(at: at)
    elsif self.whole_indicators.include?(:shape)
      return self.shape_area(at: at).in_square_meter
    end
    return nil
  end

  def area(unit = :hectare, at = Time.now)
    ActiveSupport::Deprecation.warn("Product#area is deprecated. Please use Product#net_surface_area instead.")
    return net_surface_area(at).in(unit)
  end

  def net_weight(at = Time.now)
    # if self.variable_indicators_array.include?(Nomen::Indicators[:net_weight])
    return 0.0.in_kilogram
    pop = self.population(at: at)
    if self.net_weight
      return self.net_weight(at: at)
    else
      return 0.0.in_kilogram
    end
  end

  def weight(unit = :kilogram, at = Time.now)
    ActiveSupport::Deprecation.warn("Product#area is deprecated. Please use Product#net_surface_area instead.")
    return net_weight(at).in(unit)
  end

  # Measure a product for a given indicator
  def is_measured!(indicator, value, options = {})
    unless Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    if value.nil?
      raise ArgumentError, "Value must be given"
    end
    datum = self.indicator_data.build(indicator: indicator, measured_at: (options[:at] || Time.now), originator: options[:originator])
    datum.value = value
    datum.save!
    return datum
  end


  # # Return the indicator datum
  # def indicator(indicator, options = {})
  #   ActiveSupport::Deprecation.warn("Product#indicator method is deprecated. Please use Product#indicate instead")
  #   return indicate(indicator, options)
  # end

  # Return the indicator datum
  def indicate(indicator, options = {})
    measured_at = options[:at] || Time.now
    return self.indicator_data.where(indicator: indicator.to_s).where("measured_at <= ?", measured_at).reorder("measured_at DESC").first
  end

  # Get indicator value
  # if option :at specify at which moment
  # if option :interpolate is true, it returns the interpolated value
  def get(indicator_name, *args)
    unless indicator = Nomen::Indicators.items[indicator_name]
      raise StandardError, "Unknown indicator: #{indicator_name.inspect}"
    end
    options = args.extract_options!
    measured_at = args.shift || options[:at] || Time.now
    # Find value
    value = nil
    if options[:interpolate]
      if [:measure, :decimal].include?(indicator.datatype)
        raise NotImplementedError, "Interpolation is not available for now"
      end
      raise StandardError, "Can not use :interpolate option with #{indicator.datatype.inspect} datatype"
    elsif datum = self.indicate(indicator.name, at: measured_at)
      value = datum.value
    end
    # Adjust value
    if value and indicator.gathering
      if indicator.gathering == :proportional_to_population
        value *= self.get(:population, at: measured_at)
      end
    end
    return value
  end


  # Returns indicators for a set of product
  def self.indicator(name, options = {})
    measured_at = options[:at] || Time.now
    ProductIndicatorDatum.where("id IN (SELECT p1.id FROM #{self.indicator_table_name(name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator = p2.indicator AND (p1.measured_at < p2.measured_at OR (p1.measured_at = p2.measured_at AND p1.id < p2.id)) AND p2.measured_at <= ?) WHERE p1.measured_at <= ? AND p1.product_id IN (?) AND p1.indicator = ? AND p2 IS NULL)", measured_at, measured_at, self.pluck(:id), name)
  end


  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicators.all.include?(method_name.to_s)
      return get(method_name, *args)
    end
    return super
  end

  # Give the indicator table name
  def self.indicator_table_name(indicator)
    ProductIndicatorDatum.table_name
  end

end
