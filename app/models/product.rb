# -*- coding: utf-8 -*-
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
# == Table: products
#
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string(120)
#  description           :text
#  extjuncted            :boolean          not null
#  financial_asset_id    :integer
#  id                    :integer          not null, primary key
#  identification_number :string(255)
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :spatial({:srid=>
#  lock_version          :integer          default(0), not null
#  name                  :string(255)      not null
#  nature_id             :integer          not null
#  number                :string(255)      not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string(255)
#  picture_file_name     :string(255)
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string(255)
#  updated_at            :datetime         not null
#  updater_id            :integer
#  variant_id            :integer          not null
#  variety               :string(120)      not null
#  work_number           :string(255)
#


class Product < Ekylibre::Record::Base
  include Versionable, Indicateable
  enumerize :variety, in: Nomen::Varieties.all, predicates: {prefix: true}
  enumerize :derivative_of, in: Nomen::Varieties.all
  belongs_to :address, class_name: "EntityAddress"
  belongs_to :category, class_name: "ProductNatureCategory"
  belongs_to :default_storage, class_name: "Product"
  belongs_to :financial_asset
  belongs_to :initial_container, class_name: "Product"
  belongs_to :initial_enjoyer, class_name: "Entity"
  belongs_to :initial_father, class_name: "Product"
  belongs_to :initial_mother, class_name: "Product"
  belongs_to :initial_owner, class_name: "Entity"
  belongs_to :nature, class_name: "ProductNature"
  belongs_to :parent, class_name: "Product"
  belongs_to :person
  belongs_to :tracking
  belongs_to :variant, class_name: "ProductNatureVariant"
  has_many :analyses, class_name: "Analysis", dependent: :restrict_with_exception
  has_many :carrier_linkages, class_name: "ProductLinkage", foreign_key: :carried_id, dependent: :destroy
  has_many :content_localizations, class_name: "ProductLocalization", foreign_key: :container_id
  has_many :contents, class_name: "Product", through: :content_localizations, source: :product
  has_many :enjoyments, class_name: "ProductEnjoyment", foreign_key: :product_id, dependent: :destroy
  has_many :issues, as: :target, dependent: :destroy
  has_many :intervention_casts, foreign_key: :actor_id, inverse_of: :actor, dependent: :restrict_with_exception
  # has_many :groups, :through => :memberships
  has_many :reading_tasks, class_name: "ProductReadingTask", dependent: :destroy
  # has_many :incoming_delivery_items
  has_many :junction_ways, class_name: "ProductJunctionWay", foreign_key: :road_id, dependent: :destroy
  has_many :junctions, class_name: "ProductJunction", through: :junction_ways
  has_many :linkages, class_name: "ProductLinkage", foreign_key: :carrier_id, dependent: :destroy
  has_many :links, class_name: "ProductLink", foreign_key: :product_id, dependent: :destroy
  has_many :localizations, class_name: "ProductLocalization", foreign_key: :product_id, dependent: :destroy
  has_many :markers, :through => :supports
  has_many :memberships, class_name: "ProductMembership", foreign_key: :member_id, dependent: :destroy
  has_many :outgoing_delivery_items, dependent: :restrict_with_exception
  has_many :ownerships, class_name: "ProductOwnership", foreign_key: :product_id, dependent: :destroy
  has_many :phases, class_name: "ProductPhase", dependent: :destroy
  has_many :supports, class_name: "ProductionSupport", foreign_key: :storage_id, inverse_of: :storage
  has_many :variants, class_name: "ProductNatureVariant", :through => :phases
  has_one :start_way,  -> { where(nature: 'start') },  class_name: "ProductJunctionWay", inverse_of: :road, foreign_key: :road_id
  has_one :finish_way, -> { where(nature: 'finish') }, class_name: "ProductJunctionWay", inverse_of: :road, foreign_key: :road_id
  has_one :start_junction,  through: :start_way,  source: :junction
  has_one :finish_junction, through: :finish_way, source: :junction
  has_one :current_phase,        -> { current }, class_name: "ProductPhase",        foreign_key: :product_id
  has_one :current_localization, -> { current }, class_name: "ProductLocalization", foreign_key: :product_id
  has_one :current_ownership,    -> { current }, class_name: "ProductOwnership",    foreign_key: :product_id
  has_many :current_memberships, -> { current }, class_name: "ProductMembership",    foreign_key: :product_id
  has_one :container, through: :current_localization
  has_many :groups, through: :current_memberships
  has_one :incoming_delivery_item, class_name: "IncomingDeliveryItem", foreign_key: :product_id

  has_picture

  # find Product by work_numbers (work_numbers must be an Array)
  scope :of_work_numbers, lambda { |work_numbers|
    where(work_number: work_numbers)
  }

  scope :members_of, lambda { |group, viewed_at|
    # where("id IN (SELECT member_id FROM #{ProductMembership.table_name} WHERE group_id = ? AND nature = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", group.id, "interior", viewed_at, viewed_at, viewed_at)
    where(id: ProductMembership.select(:member_id).where(group_id: group.id, nature: "interior").at(viewed_at))
  }
  scope :of_variety, lambda { |*varieties|
    where(variety: varieties.flatten.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, lambda { |*varieties|
    where(derivative_of: varieties.flatten.collect{|v| Nomen::Varieties.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :can, lambda { |*abilities|
    where(nature_id: ProductNature.can(*abilities))
  }
  scope :can_each, lambda { |*abilities|
    where(nature_id: ProductNature.can_each(*abilities))
  }

  scope :of_working_set, lambda { |working_set|
    where(nature_id: ProductNature.of_working_set(working_set))
  }

  scope :of_nature, lambda { |nature|
    where(nature_id: nature.id)
  }
  scope :of_variant, lambda { |variant, at = Time.now|
    where(variant_id: variant.id)
  }
  scope :at, lambda { |at| where(arel_table[:born_at].lteq(at).and(arel_table[:dead_at].eq(nil).or(arel_table[:dead_at].gt(at)))) }
  scope :of_owner, lambda { |owner|
    joins(:current_ownership).where("product_ownerships.owner_id" => Entity.of_company.id)
  }

  scope :of_productions, lambda { |*productions|
    productions.flatten!
    for production in productions
      raise ArgumentError.new("Expected Production, got #{production.class.name}:#{production.inspect}") unless production.is_a?(Production)
    end
    joins(:supports).merge(ProductionSupport.of_productions(productions))
  }

  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :production_supports,  -> { where(variety: ["cultivable_zone"]) }
  scope :supportables,  -> { of_variety([:cultivable_zone, :animal_group, :equipment]) }
  scope :supporters,  -> { where(id: ProductionSupport.pluck(:storage_id)) }
  scope :availables, -> { where(dead_at: nil).not_indicate(population: 0) }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :born_at, :dead_at, :initial_born_at, :initial_dead_at, :picture_updated_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_numericality_of :initial_population, allow_nil: true
  validates_length_of :derivative_of, :variety, allow_nil: true, maximum: 120
  validates_length_of :identification_number, :name, :number, :picture_content_type, :picture_file_name, :work_number, allow_nil: true, maximum: 255
  validates_inclusion_of :extjuncted, in: [true, false]
  validates_presence_of :category, :name, :nature, :number, :variant, :variety
  #]VALIDATORS]
  validates_presence_of :nature, :variant, :name
  validates_attachment_content_type :picture, content_type: /image/

  accepts_nested_attributes_for :readings, allow_destroy: true, reject_if: lambda { |reading|
    !reading["indicator_name"] != "population" and reading[ProductReading.value_column(reading["indicator_name"]).to_s].blank?
  }
  accepts_nested_attributes_for :memberships, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: true
  delegate :serial_number, :producer, to: :tracking
  delegate :name, to: :nature, prefix: true
  delegate :variety, :derivative_of, :name, :nature, :reference_name, to: :variant, prefix: true
  delegate :unit_name, to: :variant
  delegate :able_to_each?, :able_to?, :subscribing?, :deliverable?, :asset_account, :product_account, :charge_account, :stock_account, :population_counting_unitary?, to: :nature
  delegate :has_indicator?, :individual_indicators_list, :whole_indicators_list, :abilities, :abilities_list, :indicators, :indicators_list, :frozen_indicators, :frozen_indicators_list, :variable_indicators, :variable_indicators_list, :linkage_points, :linkage_points_list, to: :nature

  after_initialize :choose_default_name
  after_save :set_initial_values, if: :initializeable?
  before_validation :set_default_values, on: :create
  before_validation :update_default_values, on: :update

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
      unless Nomen::Varieties[self.variant_variety].include? self.variety.to_s
        errors.add(:variety, :invalid)
      end
      if self.derivative_of
        unless Nomen::Varieties[self.variant_derivative_of].include? self.derivative_of.to_s
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

  def available?
    self.dead_at.nil? and !self.population.zero?
  end

  def unroll_name
    return "unrolls.backend/products".t(self.attributes.symbolize_keys.merge(population: self.population, unit_name: self.unit_name))
  end

  # set initial owner and localization
  def set_initial_values
    # Add first owner on a product
    unless ownership = self.ownerships.first_of_all
      ownership = self.ownerships.build
    end
    ownership.owner = self.initial_owner
    ownership.save!

    # Add first enjoyer on a product
    unless enjoyment = self.enjoyments.first_of_all
      enjoyment = self.enjoyments.build
    end
    enjoyment.enjoyer = self.initial_enjoyer || self.initial_owner
    enjoyment.save!

    # Add first localization on a product
    if self.initial_container
      unless localization = self.localizations.first_of_all
        localization = self.localizations.build
      end
      localization.nature = :interior
      localization.container = self.initial_container
      localization.save!
    end

    unless self.extjuncted?
      # Add default start junction
      if self.start_junction
        self.start_junction.update_column(:started_at, self.initial_born_at)
        way = self.start_junction.product_way
        way.population = self.initial_population
        way.shape = self.initial_shape
        way.save!
      else
        ProductBirth.create!(product_way_attributes: {road: self, population: self.initial_population, shape: self.initial_shape}, started_at: self.initial_born_at)
        self.reload
      end

      # Add default finish junction
      if self.finish_junction
        if self.initial_dead_at
          self.finish_junction.update_column(:started_at, self.initial_dead_at)
        else
          self.finish_junction.destroy
        end
      elsif self.initial_dead_at
        ProductDeath.create!(product_way_attributes: {road: self}, started_at: self.initial_dead_at)
        self.reload
      end
    end

    # Add first frozen indicator on a product from his variant
    if self.variant
      unless phase = self.phases.first_of_all
        phase = self.phases.build
      end
      phase.variant = self.variant
      phase.save!
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
	require 'ffaker' unless defined? Faker
        self.name = Faker::Name.first_name
      end
    end
  end

  # Sets nature and variety from variant
  def set_default_values
    if self.variant
      self.nature_id    = self.variant.nature_id
      self.variety ||= self.variant.variety
      if self.derivative_of.blank? and not self.variant.derivative_of.blank?
        self.derivative_of = self.variant.derivative_of
      end
    end
    if self.nature
      self.category_id = self.nature.category_id
    end
  end

  # Update nature and variety and variant from phase
  def update_default_values
    if self.current_phase
      phase_variant = self.current_phase.variant
      self.nature_id    = phase_variant.nature_id
      self.variety    ||= phase_variant.variety
      if self.derivative_of.blank? and not phase_variant.derivative_of.nil?
        self.derivative_of = phase_variant.derivative_of
      end
    end
    if self.nature
      self.category_id = self.nature.category_id
    end
  end

  # Returns the matching model for the record
  def matching_model
    return ProductNature.matching_model(self.variety)
  end


  # Returns the price for the product.
  # It's a shortcut for CatalogItem::give
  def price(options = {})
    return CatalogItem.price(self, options)
  end


  # Returns age in seconds of the product
  def age(at = Time.now)
    return nil if self.born_at.nil? or self.born_at >= at
    return ((self.dead_at || at) - self.born_at)
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
    incoming_item = self.incoming_delivery_item
    incoming_purchase_item = incoming_item.purchase_item if incoming_item
    outgoing_item = self.outgoing_delivery_items.first
    outgoing_sale_item = outgoing_item.sale_item if outgoing_item

    if incoming_purchase_item
      # search a price in purchase item via incoming item price
      price = incoming_purchase_item.unit_pretax_amount
    elsif outgoing_sale_item
      # search a price in sale item via outgoing item price
      price = outgoing_sale_item.unit_pretax_amount
    elsif catalog_item = self.variant.catalog_items.limit(1).first
      # search a price in catalog price
      if catalog_item.all_taxes_included == true
        price = catalog_item.reference_tax.pretax_amount_of(catalog_item.amount)
      else
        price = catalog_item.amount
      end
    else
      price = nil
    end
    return price
  end

  def dead?
    return !self.finish_way.nil?
  end

  # Returns groups of the product at a given time (or now by default)
  def groups_at(viewed_at = nil)
    ProductGroup.groups_of(self, viewed_at || Time.now)
  end

  # Returns the current contents of the product at a given time (or now by default)
  def contains(varieties = :product, at = Time.now)
    localizations = self.content_localizations.at(at).of_product_varieties(varieties)
    if localizations.any?
      #object = []
      #for localization in localizations
        #object << localization.product if localization.product.is_a?(stored_class)
      #end
      return localizations
     else
       return nil
    end
  end

  def containeds(at = Time.now)
    list = []
    for localization in ProductLocalization.where(container_id: self.id).at(at)
      list << localization.product
      list += localization.product.containeds(at)
    end
    return list
  end

  def contents_name(at = Time.now)
    self.containeds.map(&:name).compact.to_sentence
  end

  # Returns the current container for the product
  def owner
    if o = self.current_ownership
      return o.owner
    end
    return nil
  end

  # Returns the container for the product at a given time
  def container_at(at)
    if l = self.localizations.at(at).first
      return l.container
    end
    return nil
  end

  def picture_path(style=:original)
    self.picture.path(style)
  end

  def initial_shape=(value)
    if value.is_a?(String) and value =~ /\A\{.*\}\z/
      value = Charta::Geometry.new(JSON.parse(value).to_json, :WGS84).to_rgeo
    elsif !value.blank?
      value = Charta::Geometry.new(value).to_rgeo
    end
    self["initial_shape"] = value
  end

  # Returns all contained products of the given variant
  def localized_variants(variant, options = {})
    options[:at] ||= Time.now
    return self.containeds.select{|p| p.variant == variant }
  end

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


  def initializeable?
    self.new_record? or !(self.incoming_delivery_item.present? or self.outgoing_delivery_items.any? or self.intervention_casts.any? or self.financial_asset.present?)
  end


  def variables(options = {})
    list = []
    abilities = self.abilities
    variety       = Nomen::Varieties[self.variety]
    derivative_of = Nomen::Varieties[self.derivative_of]
    Procedo.each_variable do |variable|
      next if variable.new?
      if v = variable.computed_variety
        next unless variety <= v
      end
      if v = variable.computed_derivative_of
        next unless derivative_of and derivative_of <= v
      end
      next if variable.abilities.detect{|a| !self.able_to?(a) }
      list << variable
    end
    return list
  end

end
