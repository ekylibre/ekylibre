# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  derivative_of         :string
#  description           :text
#  fixed_asset_id        :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :geometry({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_movement_id   :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  nature_id             :integer          not null
#  number                :string           not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string
#  picture_file_name     :string
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string
#  updated_at            :datetime         not null
#  updater_id            :integer
#  uuid                  :uuid
#  variant_id            :integer          not null
#  variety               :string           not null
#  work_number           :string
#

require 'ffaker'

class Product < Ekylibre::Record::Base
  include Versionable, Indicateable, Attachable
  refers_to :variety
  refers_to :derivative_of, class_name: 'Variety'
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :category, class_name: 'ProductNatureCategory'
  belongs_to :default_storage, class_name: 'Product'
  belongs_to :fixed_asset
  belongs_to :initial_container, class_name: 'Product'
  belongs_to :initial_enjoyer, class_name: 'Entity'
  belongs_to :initial_movement, class_name: 'ProductMovement'
  belongs_to :initial_father, class_name: 'Product'
  belongs_to :initial_mother, class_name: 'Product'
  belongs_to :initial_owner, class_name: 'Entity'
  belongs_to :nature, class_name: 'ProductNature'
  belongs_to :parent, class_name: 'Product'
  belongs_to :person, -> { contacts }, class_name: 'Entity'
  belongs_to :tracking
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :activity_productions, foreign_key: :support_id
  has_many :analyses, class_name: 'Analysis', dependent: :restrict_with_exception
  has_many :carrier_linkages, class_name: 'ProductLinkage', foreign_key: :carried_id, dependent: :destroy
  has_many :content_localizations, class_name: 'ProductLocalization', foreign_key: :container_id
  has_many :contents, class_name: 'Product', through: :content_localizations, source: :product
  has_many :distributions, class_name: 'TargetDistribution', foreign_key: :target_id, inverse_of: :target, dependent: :destroy
  has_many :enjoyments, class_name: 'ProductEnjoyment', foreign_key: :product_id, dependent: :destroy
  # has_many :groups, :through => :memberships
  has_many :issues, as: :target, dependent: :destroy
  has_many :intervention_product_parameters, foreign_key: :product_id, inverse_of: :product, dependent: :restrict_with_exception
  has_many :interventions, through: :intervention_product_parameters
  has_many :linkages, class_name: 'ProductLinkage', foreign_key: :carrier_id, dependent: :destroy
  has_many :links, class_name: 'ProductLink', foreign_key: :product_id, dependent: :destroy
  has_many :localizations, class_name: 'ProductLocalization', foreign_key: :product_id, dependent: :destroy
  has_many :memberships, class_name: 'ProductMembership', foreign_key: :member_id, dependent: :destroy
  has_many :movements, class_name: 'ProductMovement', foreign_key: :product_id, dependent: :destroy
  has_many :ownerships, class_name: 'ProductOwnership', foreign_key: :product_id, dependent: :destroy
  has_many :parcel_items, dependent: :restrict_with_exception
  has_many :phases, class_name: 'ProductPhase', dependent: :destroy
  has_many :sensors
  has_many :supports, class_name: 'ActivityProduction', foreign_key: :support_id, inverse_of: :support
  has_many :variants, class_name: 'ProductNatureVariant', through: :phases
  has_one :current_phase,        -> { current }, class_name: 'ProductPhase',        foreign_key: :product_id
  has_one :current_localization, -> { current }, class_name: 'ProductLocalization', foreign_key: :product_id
  has_one :current_enjoyment,    -> { current }, class_name: 'ProductEnjoyment',    foreign_key: :product_id
  has_one :current_ownership,    -> { current }, class_name: 'ProductOwnership',    foreign_key: :product_id
  has_many :current_memberships, -> { current }, class_name: 'ProductMembership', foreign_key: :member_id
  has_one :container, through: :current_localization
  has_many :groups, through: :current_memberships
  # FIXME: These reflections are meaningless. Will be removed soon or later.
  has_one :incoming_parcel_item, class_name: 'ParcelItem', foreign_key: :product_id, inverse_of: :product
  has_one :outgoing_parcel_item, class_name: 'ParcelItem', foreign_key: :product_id, inverse_of: :product

  has_picture
  has_geometry :initial_shape, type: :multi_polygon
  has_geometry :initial_geolocation, type: :point

  # find Product by work_numbers (work_numbers must be an Array)
  scope :of_work_numbers, lambda { |work_numbers|
    where(work_number: work_numbers)
  }

  scope :members_of, lambda { |group, viewed_at|
    where(id: ProductMembership.select(:member_id).where(group_id: group.id, nature: 'interior').at(viewed_at))
  }

  scope :members_of_place, ->(place, viewed_at) { contained_by(place, viewed_at) }
  scope :contained_by, lambda { |container, viewed_at = Time.zone.now|
    where(id: ProductLocalization.select(:product_id).where(container: container).at(viewed_at))
  }
  scope :of_variety, lambda { |*varieties|
    where(variety: varieties.flatten.collect { |v| Nomen::Variety.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :derivative_of, lambda { |*varieties|
    where(derivative_of: varieties.flatten.collect { |v| Nomen::Variety.all(v.to_sym) }.flatten.map(&:to_s).uniq)
  }
  scope :can, lambda { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' or '))
  }
  scope :can_each, lambda { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  }
  scope :of_working_set, lambda { |working_set|
    item = Nomen::WorkingSet.find(working_set)
    fail StandardError, "#{working_set.inspect} is not in Nomen::WorkingSet nomenclature" unless item
    of_expression(item.expression)
  }
  scope :of_expression, lambda { |expression|
    joins(:nature).where(WorkingSet.to_sql(expression, default: :products, abilities: :product_natures, indicators: :product_natures))
  }
  scope :of_nature, lambda { |nature|
    where(nature_id: nature.id)
  }
  scope :of_variant, lambda { |variant, _at = Time.zone.now|
    where(variant_id: (variant.is_a?(ProductNatureVariant) ? variant.id : variant))
  }
  scope :at, ->(at) { where(arel_table[:born_at].lteq(at).and(arel_table[:dead_at].eq(nil).or(arel_table[:dead_at].gt(at)))) }
  scope :of_owner, lambda { |owner|
    if owner.is_a?(Symbol)
      joins(:current_ownership).where(product_ownerships: { nature: owner })
    else
      joins(:current_ownership).where(product_ownerships: { owner_id: owner.id })
    end
  }
  scope :of_enjoyer, lambda { |enjoyer|
    if enjoyer.is_a?(Symbol)
      joins(:current_enjoyment).where(product_enjoyments: { nature: enjoyer })
    else
      joins(:current_enjoyment).where(product_enjoyments: { enjoyer_id: enjoyer.id })
    end
  }

  scope :of_production, lambda { |production|
    where(id: TargetDistribution.select(:target_id).where(activity_production: production))
  }
  scope :of_productions, lambda { |*productions|
    of_productions(productions.flatten)
  }

  scope :supports_of_campaign, lambda { |campaign|
    joins(:supports).merge(ActivityProduction.of_campaign(campaign))
  }
  scope :intersects_shape, lambda { |shape|
    where(id: ProductReading.where('ST_Intersects(multi_polygon_value, ST_GeomFromEWKT(?))', ::Charta.new_geometry(shape).to_ewkt).select(:product_id))
  }
  scope :within_shape, lambda { |shape|
    where(id: ProductReading.where('ST_Within(multi_polygon_value, ST_GeomFromEWKT(?))', ::Charta.new_geometry(shape).to_ewkt).select(:product_id))
  }
  scope :covers_shape, lambda { |shape|
    where(id: ProductReading.where('ST_Covers(multi_polygon_value, ST_GeomFromEWKT(?))', ::Charta.new_geometry(shape).to_ewkt).select(:product_id))
  }
  scope :overlaps_shape, lambda { |shape|
    where(id: ProductReading.where('ST_Overlaps(multi_polygon_value, ST_GeomFromEWKT(?))', ::Charta.new_geometry(shape).to_ewkt).select(:product_id))
  }

  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :production_supports, -> { where(variety: ['cultivable_zone']) }
  scope :supportables, -> { of_variety([:cultivable_zone, :animal_group, :equipment]) }
  scope :supporters, -> { where(id: ActivityProduction.pluck(:support_id)) }
  scope :available, -> { where(dead_at: nil) }
  scope :availables, -> { available }
  scope :tools, -> { of_variety(:equipment) }
  scope :support, -> { joins(:nature).merge(ProductNature.support) }

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :born_at, :dead_at, :initial_born_at, :initial_dead_at, :picture_updated_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :picture_file_size, allow_nil: true, only_integer: true
  validates_numericality_of :initial_population, allow_nil: true
  validates_presence_of :category, :name, :nature, :number, :variant, :variety
  # ]VALIDATORS]
  validates_length_of :derivative_of, :variety, allow_nil: true, maximum: 120
  validates_presence_of :nature, :variant, :name, :uuid
  validates_attachment_content_type :picture, content_type: /image/

  accepts_nested_attributes_for :readings, allow_destroy: true, reject_if: lambda { |reading|
    !reading['indicator_name'] != 'population' && reading[ProductReading.value_column(reading['indicator_name']).to_s].blank?
  }
  accepts_nested_attributes_for :memberships, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: true
  delegate :serial_number, :producer, to: :tracking
  delegate :name, to: :nature, prefix: true
  delegate :variety, :derivative_of, :name, :nature, :reference_name,
           to: :variant, prefix: true
  delegate :unit_name, to: :variant
  delegate :able_to_each?, :able_to?, :of_expression, :subscribing?,
           :deliverable?, :asset_account, :product_account, :charge_account,
           :stock_account, :population_counting_unitary?, to: :nature
  delegate :has_indicator?, :individual_indicators_list, :whole_indicators_list,
           :abilities, :abilities_list, :indicators, :indicators_list,
           :frozen_indicators, :frozen_indicators_list, :variable_indicators,
           :variable_indicators_list, :linkage_points, :linkage_points_list,
           to: :nature

  after_initialize :choose_default_name
  after_save :set_initial_values, if: :initializeable?
  before_validation :set_default_values, on: :create
  before_validation :update_default_values, on: :update

  before_validation do
    self.uuid ||= UUIDTools::UUID.random_create.to_s
  end

  after_validation do
    self.default_storage ||= initial_container
    self.initial_container ||= self.default_storage
  end

  validate do
    if self.nature && self.variant
      errors.add(:nature_id, :invalid) if self.variant.nature_id != nature_id
    end
    if self.variant
      if variety
        unless Nomen::Variety.find(variant_variety) >= variety
          errors.add(:variety, :invalid)
        end
      end
      if derivative_of
        unless Nomen::Variety.find(variant_derivative_of) >= derivative_of
          errors.add(:derivative_of, :invalid)
        end
      end
    end
  end

  protect(on: :destroy) do
    analyses.any? || intervention_product_parameters.any? || issues.any? || parcel_items.any? || supports.any?
  end

  class << self
    # Auto-cast product to best matching class with type column
    def new_with_cast(*attributes, &block)
      if (h = attributes.first).is_a?(Hash) && !h.nil? && (type = h[:type] || h['type']) && type.length > 0 && (klass = type.constantize) != self
        fail "Can not cast #{name} to #{klass.name}" unless klass <= self
        return klass.new(*attributes, &block)
      end
      new_without_cast(*attributes, &block)
    end
    alias_method_chain :new, :cast
  end

  # TODO: Removes this ASAP
  def deliverable?
    false
  end

  def available?
    dead_at.nil? && !population.zero?
  end

  def work_name
    "#{name} (#{work_number})"
  end

  def unroll_name
    'unrolls.backend/products'.t(attributes.symbolize_keys.merge(population: population, unit_name: unit_name))
  end

  # set initial owner and localization
  def set_initial_values
    self.initial_born_at ||= Time.zone.now

    # Add first owner on a product
    unless ownership = ownerships.first_of_all
      ownership = ownerships.build
    end
    ownership.owner = initial_owner
    ownership.save!

    # Add first enjoyer on a product
    unless enjoyment = enjoyments.first_of_all
      enjoyment = enjoyments.build
    end
    enjoyment.enjoyer = initial_enjoyer || initial_owner
    enjoyment.save!

    # Add first localization on a product
    if self.initial_container
      unless localization = localizations.first_of_all
        localization = localizations.build
      end
      localization.nature = :interior
      localization.container = self.initial_container
      localization.save!
    end

    self.born_at ||= self.initial_born_at
    self.dead_at ||= initial_dead_at

    if born_at
      build_initial_movement unless initial_movement
      initial_movement.product = self
      initial_movement.delta = initial_population
      initial_movement.started_at = born_at
      initial_movement.save!
      if initial_shape && variable_indicators_list.include?(:shape)
        read!(:shape, initial_shape, at: born_at)
      end
    end

    # Add first frozen indicator on a product from his variant
    if variant
      unless phase = phases.first_of_all
        phase = phases.build
      end
      phase.variant = variant
      phase.save!
    end
  end

  # Try to find the best name for the new products
  def choose_default_name
    if name.blank?
      if variant
        if last = variant.products.reorder(id: :desc).first
          self.name = last.name
          array = name.split(/\s+/)
          if array.last.match(/^\(+\d+\)+?$/)
            self.name = array[0..-2].join(' ') + ' (' + array.last.gsub(/(^\(+|\)+$)/, '').to_i.succ.to_s + ')'
          else
            name << ' (1)'
          end
        else
          self.name = variant_name
        end
      end
      if name.blank?
        # By default, choose a random name
        self.name = ::FFaker::Name.first_name
      end
    end
  end

  # Sets nature and variety from variant
  def set_default_values
    if variant
      self.nature_id = variant.nature_id
      self.variety ||= variant.variety
      if derivative_of.blank? && !variant.derivative_of.blank?
        self.derivative_of = variant.derivative_of
      end
    end
    self.category_id = nature.category_id if nature
  end

  # Update nature and variety and variant from phase
  def update_default_values
    if current_phase
      phase_variant = current_phase.variant
      self.nature_id = phase_variant.nature_id
      self.variety ||= phase_variant.variety
      if derivative_of.blank? && !phase_variant.derivative_of.nil?
        self.derivative_of = phase_variant.derivative_of
      end
    end
    self.category_id = nature.category_id if nature
  end

  # Returns the matching model for the record
  def matching_model
    ProductNature.matching_model(self.variety)
  end

  # Returns the price for the product.
  # It's a shortcut for CatalogItem::give
  def price(options = {})
    CatalogItem.price(self, options)
  end

  # Returns age in seconds of the product
  def age(at = Time.zone.now)
    return 0 if born_at.nil? || born_at >= at
    ((dead_at || at) - born_at)
  end

  # Returns an evaluated price (without taxes) for the product in an intervention context
  # options could contains a parameter :at for the datetime of a catalog price
  # unit_price in a purchase context
  # or unit_price in a sale context
  # or unit_price in catalog price
  def evaluated_price(_options = {})
    filter = {
      variant_id: variant_id
    }
    incoming_item = incoming_parcel_item
    incoming_purchase_item = incoming_item.purchase_item if incoming_item
    outgoing_item = parcel_items.with_nature(:outgoing).first
    outgoing_sale_item = outgoing_item.sale_item if outgoing_item

    if incoming_purchase_item
      # search a price in purchase item via incoming item price
      price = incoming_purchase_item.unit_pretax_amount
    elsif outgoing_sale_item
      # search a price in sale item via outgoing item price
      price = outgoing_sale_item.unit_pretax_amount
    elsif catalog_item = variant.catalog_items.limit(1).first
      # search a price in catalog price
      if catalog_item.all_taxes_included == true
        price = catalog_item.reference_tax.pretax_amount_of(catalog_item.amount)
      else
        price = catalog_item.amount
      end
    else
      price = nil
    end
    price
  end

  def dead?
    !finish_way.nil?
  end

  # Returns groups of the product at a given time (or now by default)
  def groups_at(viewed_at = nil)
    ProductGroup.groups_of(self, viewed_at || Time.zone.now)
  end

  # add products to current container
  def add_content_products(products, options = {})
    Intervention.write(:product_moving, options) do |i|
      i.cast :container, self, as: 'product_moving-container'
      products.each do |p|
        product = (p.is_a?(Product) ? p : Product.find(p))
        member = i.cast :product, product, as: 'product_moving-target'
        i.movement member, :container
      end
    end
  end

  def population(options = {})
    movements = self.movements.at(options[:at] || Time.zone.now)
    (movements.any? ? movements.first.population : 0.0)
  end

  # Moves population with given quantity
  def move!(quantity, options = {})
    movements.create!(delta: quantity, started_at: options[:at])
  end

  # Returns the container for the product at a given time
  def container_at(at)
    if l = localizations.at(at).first
      return l.container
    end
    nil
  end

  # Returns the current contents of the product at a given time (or now by default)
  def contains(varieties = :product, at = Time.zone.now)
    localizations = content_localizations.at(at).of_product_varieties(varieties)
    if localizations.any?
      # object = []
      # for localization in localizations
      # object << localization.product if localization.product.is_a?(stored_class)
      # end
      return localizations
    else
      return nil
    end
  end

  def containeds(at = Time.zone.now)
    list = []
    for localization in ProductLocalization.where(container_id: id).at(at)
      list << localization.product
      list += localization.product.containeds(at)
    end
    list
  end

  def contents_name(_at = Time.zone.now)
    containeds.map(&:name).compact.to_sentence
  end

  # Returns the current ownership for the product
  def owner
    if o = current_ownership
      return o.owner
    end
    nil
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  # Returns all contained products of the given variant
  def localized_variants(variant, options = {})
    options[:at] ||= Time.zone.now
    containeds.select { |p| p.variant == variant }
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicator.all.include?(method_name.to_s.gsub(/\!\z/, ''))
      if method_name.to_s =~ /\!\z/
        return get!(method_name.to_s.gsub(/\!\z/, ''), *args)
      else
        return get(method_name, *args)
      end
    end
    super
  end

  # Create a new product parted from self
  # See part!
  def part_with!(population, options = {})
    product = part_with(population, options)
    product.save!
    product
  end

  # Build a new product parted from self
  # No product_division created.
  # Options can be shape, name, born_at
  def part_with(population, options = {})
    attributes = options.slice(:name, :number, :work_number, :identification_number, :tracking, :default_storage, :description, :picture)
    attributes[:name] ||= name
    attributes[:tracking] ||= tracking
    attributes[:variant] = variant
    # Initial values
    attributes[:initial_population] = population
    attributes[:initial_shape] ||= options[:shape] || shape
    attributes[:initial_born_at] = options[:born_at] if options[:born_at]
    attributes[:initial_dead_at] = options[:dead_at] if options[:dead_at]
    ownership = current_ownership
    if ownership && !ownership.unknown?
      attributes[:initial_owner] ||= ownership.owner
    end
    enjoyment = current_enjoyment
    if enjoyment && !enjoyment.unknown?
      attributes[:initial_enjoyer] ||= enjoyment.enjoyer
    end
    localization = current_localization
    if localization && localization.interior?
      attributes[:initial_container] ||= localization.container
    end
    matching_model.new(attributes)
  end

  def initializeable?
    self.new_record? || !(parcel_items.any? || intervention_product_parameters.any? || fixed_asset.present?)
  end

  # TODO: Doc
  def variables(_options = {})
    list = []
    abilities = self.abilities
    variety       = Nomen::Variety[self.variety]
    derivative_of = Nomen::Variety[self.derivative_of]
    Procedo.each_variable do |variable|
      next if variable.new?
      if v = variable.computed_variety
        next unless variety <= v
      end
      if v = variable.computed_derivative_of
        next unless derivative_of && derivative_of <= v
      end
      next if variable.abilities.detect { |a| !self.able_to?(a) }
      list << variable
    end
    list
  end

  # Returns working duration of a product
  def working_duration(options = {})
    role = options[:as] || :tool
    periods = InterventionWorkingPeriod.with_generic_cast(role, self)
    periods = periods.of_campaign(options[:campaign]) if options[:campaign]
    periods.sum(:duration)
  end
end
