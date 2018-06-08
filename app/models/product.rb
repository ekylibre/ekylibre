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
# == Table: products
#
#  activity_production_id       :integer
#  address_id                   :integer
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer          not null
#  codes                        :jsonb
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  default_storage_id           :integer
#  derivative_of                :string
#  description                  :text
#  end_of_life_reason           :string
#  father_country               :string
#  father_identification_number :string
#  father_variety               :string
#  filiation_status             :string
#  first_calving_on             :datetime
#  fixed_asset_id               :integer
#  id                           :integer          not null, primary key
#  identification_number        :string
#  initial_born_at              :datetime
#  initial_container_id         :integer
#  initial_dead_at              :datetime
#  initial_enjoyer_id           :integer
#  initial_father_id            :integer
#  initial_geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  initial_mother_id            :integer
#  initial_movement_id          :integer
#  initial_owner_id             :integer
#  initial_population           :decimal(19, 4)   default(0.0)
#  initial_shape                :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version                 :integer          default(0), not null
#  member_variant_id            :integer
#  mother_country               :string
#  mother_identification_number :string
#  mother_variety               :string
#  name                         :string           not null
#  nature_id                    :integer          not null
#  number                       :string           not null
#  origin_country               :string
#  origin_identification_number :string
#  originator_id                :integer
#  parent_id                    :integer
#  person_id                    :integer
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer
#  picture_updated_at           :datetime
#  reading_cache                :jsonb            default("{}")
#  team_id                      :integer
#  tracking_id                  :integer
#  type                         :string
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  uuid                         :uuid
#  variant_id                   :integer          not null
#  variety                      :string           not null
#  work_number                  :string
#

require 'ffaker'

class Product < Ekylibre::Record::Base
  include Attachable
  include Indicateable
  include Versionable
  include Customizable
  refers_to :variety
  refers_to :derivative_of, class_name: 'Variety'
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :category, class_name: 'ProductNatureCategory'
  belongs_to :default_storage, class_name: 'Product'
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
  # belongs_to :production, class_name: 'ActivityProduction'
  belongs_to :activity_production
  has_many :activity_productions, foreign_key: :support_id
  has_many :analyses, class_name: 'Analysis', dependent: :restrict_with_exception
  has_many :carrier_linkages, class_name: 'ProductLinkage', foreign_key: :carried_id, dependent: :destroy
  has_many :content_localizations, class_name: 'ProductLocalization', foreign_key: :container_id
  has_many :contents, class_name: 'Product', through: :content_localizations, source: :product
  has_many :enjoyments, class_name: 'ProductEnjoyment', foreign_key: :product_id, dependent: :destroy
  has_many :fixed_assets, inverse_of: :product
  # has_many :groups, :through => :memberships
  has_many :issues, as: :target, dependent: :destroy
  has_many :intervention_product_parameters, -> { unscope(where: :type).of_generic_roles(%i[input output target doer tool]) }, foreign_key: :product_id, inverse_of: :product, dependent: :restrict_with_exception
  has_many :interventions, through: :intervention_product_parameters
  has_many :used_intervention_parameters, -> { unscope(where: :type).of_generic_roles(%i[input target doer tool]) }, foreign_key: :product_id, inverse_of: :product, dependent: :restrict_with_exception, class_name: 'InterventionProductParameter'
  has_many :interventions_used_in, through: :used_intervention_parameters, source: :intervention
  has_many :labellings, class_name: 'ProductLabelling', dependent: :destroy, inverse_of: :product
  has_many :labels, through: :labellings
  has_many :linkages, class_name: 'ProductLinkage', foreign_key: :carrier_id, dependent: :destroy
  has_many :links, class_name: 'ProductLink', foreign_key: :product_id, dependent: :destroy
  has_many :localizations, class_name: 'ProductLocalization', foreign_key: :product_id, dependent: :destroy
  has_many :memberships, class_name: 'ProductMembership', foreign_key: :member_id, dependent: :destroy
  has_many :movements, class_name: 'ProductMovement', foreign_key: :product_id, dependent: :destroy
  has_many :populations, class_name: 'ProductPopulation', foreign_key: :product_id, dependent: :destroy
  has_many :ownerships, class_name: 'ProductOwnership', foreign_key: :product_id, dependent: :destroy
  has_many :inspections, class_name: 'Inspection', foreign_key: :product_id, dependent: :destroy
  has_many :parcel_item_storings, foreign_key: :product_id
  has_many :parcel_items, through: :parcel_item_storings, dependent: :restrict_with_exception
  has_many :phases, class_name: 'ProductPhase', dependent: :destroy
  has_many :intervention_participations, class_name: 'InterventionParticipation', dependent: :destroy
  has_many :sensors
  has_many :supports, class_name: 'ActivityProduction', foreign_key: :support_id, inverse_of: :support
  has_many :trackings, class_name: 'Tracking', foreign_key: :product_id, inverse_of: :product
  has_many :variants, class_name: 'ProductNatureVariant', through: :phases
  has_many :purchase_items, class_name: 'PurchaseItem', inverse_of: :equipment
  has_one :current_phase,        -> { current }, class_name: 'ProductPhase',        foreign_key: :product_id
  has_one :current_localization, -> { current }, class_name: 'ProductLocalization', foreign_key: :product_id
  has_one :current_enjoyment,    -> { current }, class_name: 'ProductEnjoyment',    foreign_key: :product_id
  has_one :current_ownership,    -> { current }, class_name: 'ProductOwnership',    foreign_key: :product_id
  has_one :owner, through: :current_ownership
  has_many :current_memberships, -> { current }, class_name: 'ProductMembership', foreign_key: :member_id
  has_one :container, through: :current_localization
  has_many :groups, through: :current_memberships
  # FIXME: These reflections are meaningless. Will be removed soon or later.
  has_one :incoming_parcel_item, -> { with_nature(:incoming) }, class_name: 'ReceptionItem', foreign_key: :product_id, inverse_of: :product
  has_one :outgoing_parcel_item, -> { with_nature(:outgoing) }, class_name: 'ShipmentItem', foreign_key: :product_id, inverse_of: :product
  has_one :last_intervention_target, -> { order(id: :desc).limit(1) }, class_name: 'InterventionTarget'
  belongs_to :member_variant, class_name: 'ProductNatureVariant'

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
  scope :derivative_of, ->(*varieties) { of_derivative_of(*varieties) }
  scope :can, lambda { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' or '))
  }
  scope :can_each, lambda { |*abilities|
    of_expression(abilities.map { |a| "can #{a}" }.join(' and '))
  }
  scope :of_working_set, lambda { |working_set|
    item = Nomen::WorkingSet.find(working_set)
    raise StandardError, "#{working_set.inspect} is not in Nomen::WorkingSet nomenclature" unless item
    of_expression(item.expression)
  }
  scope :of_expression, lambda { |expression|
    joins(:nature).where(WorkingSet.to_sql(expression, default: :products, abilities: :product_natures, indicators: :product_natures))
  }
  scope :of_nature, ->(nature) { where(nature_id: nature.try(:id) || nature) }
  scope :of_variant, lambda { |variant, _at = Time.zone.now|
    where(variant_id: (variant.is_a?(ProductNatureVariant) ? variant.id : variant))
  }
  scope :at, ->(at) { where(arel_table[:born_at].lteq(at).and(arel_table[:dead_at].eq(nil).or(arel_table[:dead_at].gteq(at)))) }
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
    where(activity_production: production)
  }
  scope :of_productions, lambda { |*productions|
    of_productions(productions.flatten)
  }

  scope :of_crumbs, lambda { |*crumbs|
    options = crumbs.extract_options!
    crumbs.flatten!
    raw_products = Product.distinct.joins(:readings)
                          .joins("INNER JOIN crumbs ON (product_readings.indicator_datatype = 'shape' AND ST_Contains(ST_CollectionExtract(product_readings.geometry_value, 3), crumbs.geolocation))")
                          .where(crumbs.any? ? ['crumbs.id IN (?)', crumbs.map(&:id)] : 'crumbs.id IS NOT NULL')
    contents = []
    contents = raw_products.map(&:contents) unless options[:no_contents]
    raw_products.concat(contents).flatten.uniq
  }

  scope :generic_supports, -> { where(type: %w[Animal AnimalGroup Plant LandParcel Equipment EquipmentFleet]) }

  scope :supports_of_campaign, lambda { |campaign|
    joins(:supports).merge(ActivityProduction.of_campaign(campaign))
  }
  scope :shape_intersecting, lambda { |shape|
    where(id: ProductReading.multi_polygon_value_intersecting(shape).select(:product_id))
  }
  scope :shape_within, lambda { |shape|
    where(id: ProductReading.multi_polygon_value_within(shape).select(:product_id))
  }
  scope :shape_covering, lambda { |shape, margin = 0.02|
    where(id: ProductReading.multi_polygon_value_covering(shape, margin).select(:product_id))
  }
  scope :shape_overlapping, lambda { |shape|
    where(id: ProductReading.multi_polygon_value_overlapping(shape).select(:product_id))
  }
  scope :shape_matching, lambda { |shape, margin = 0.05|
    where(id: ProductReading.multi_polygon_value_matching(shape, margin).select(:product_id))
  }

  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :saleables, -> { joins(:nature).merge(ProductNature.saleables) }
  scope :deliverables, -> { joins(:nature).merge(ProductNature.stockables) }
  scope :depreciables, -> { joins(:nature).merge(ProductNature.depreciables) }
  scope :production_supports, -> { where(variety: ['cultivable_zone']) }
  scope :supportables, -> { of_variety(%i[cultivable_zone animal_group equipment]) }
  scope :supporters, -> { where(id: ActivityProduction.pluck(:support_id)) }
  scope :available, -> {}
  scope :availables, ->(**args) {
    at = args[:at]
    return available if at.blank?
    if at.is_a?(String)
      if at =~ /\A\d\d\d\d\-\d\d\-\d\d \d\d\:\d\d/
        available.at(Time.strptime(at, '%Y-%m-%d %H:%M'))
      else
        logger.warn('Cannot parse: ' + at)
        available
      end
    else
      available.at(at)
    end
  }
  scope :alive, -> { where(dead_at: nil) }
  scope :identifiables, -> { where(nature: ProductNature.identifiables) }
  scope :tools, -> { of_variety(:equipment) }
  scope :support, -> { joins(:nature).merge(ProductNature.support) }
  scope :storage, -> { of_expression('is building_division or can store(product) or can store_liquid or can store_fluid or can store_gaz') }
  scope :plants, -> { where(type: 'Plant') }

  scope :mine, -> { of_owner(:own) }
  scope :mine_or_undefined, ->(at = nil) {
    at ||= Time.zone.now
    where.not(id: ProductOwnership.select(:product_id).where(nature: :other).at(at))
  }

  scope :usable_in_fixed_asset, -> { depreciables.joins('LEFT JOIN fixed_assets ON products.id = fixed_assets.product_id').where('fixed_assets.id IS NULL') }

  scope :with_id, lambda { |id|
    where(id: id)
  }

  scope :of_activity_production, lambda { |activity_production|
    where(activity_production: activity_production)
  }

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :birth_date_completeness, :birth_farm_number, :country, :end_of_life_reason, :father_country, :father_identification_number, :father_variety, :filiation_status, :identification_number, :mother_country, :mother_identification_number, :mother_variety, :origin_country, :origin_identification_number, :picture_content_type, :picture_file_name, :work_number, length: { maximum: 500 }, allow_blank: true
  validates :born_at, :dead_at, :first_calving_on, :initial_born_at, :initial_dead_at, :picture_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :initial_population, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :picture_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :category, :nature, :variant, :variety, presence: true
  # ]VALIDATORS]
  validates :derivative_of, :variety, length: { allow_nil: true, maximum: 120 }
  validates :nature, :variant, :name, :uuid, presence: true
  validates_attachment_content_type :picture, content_type: /image/

  validate :born_at_in_interventions, if: ->(product) { product.born_at? && product.interventions_used_in.pluck(:started_at).any? }
  validate :dead_at_in_interventions, if: ->(product) { product.dead_at? && product.interventions.pluck(:stopped_at).any? }

  store :reading_cache, accessors: Nomen::Indicator.all, coder: ReadingsCoder

  after_commit do
    if nature.population_counting_unitary? && population.zero?
      m = movements.build(delta: 1, started_at: Time.now)
      m.save!
    end
  end

  # [DEPRECATIONS[
  #  - fixed_asset_id
  # ]DEPRECATIONS]
  def read_store_attribute(store_attribute, key)
    store = send(store_attribute)
    if store.key?(key)
      super
    else
      get(key)
    end
  end

  def born_at_in_interventions
    return true unless first_intervention = interventions_used_in.order(started_at: :asc).first
    first_used_at = first_intervention.started_at
    errors.add(:born_at, :on_or_before, restriction: first_used_at.l) if born_at > first_used_at
  end

  def dead_at_in_interventions
    last_used_at = interventions.order(stopped_at: :desc).first.stopped_at
    if dead_at < last_used_at
      # puts ActivityProduction.find_by(support_id: self.id).id.green
      errors.add(:dead_at, :on_or_after, restriction: last_used_at.l)
    end
  end

  accepts_nested_attributes_for :readings, allow_destroy: true, reject_if: lambda { |reading|
    !reading['indicator_name'] != 'population' && reading[ProductReading.value_column(reading['indicator_name']).to_s].blank?
  }
  accepts_nested_attributes_for :memberships, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :labellings, reject_if: :all_blank, allow_destroy: true
  acts_as_numbered force: true
  delegate :serial_number, :producer, to: :tracking
  delegate :variety, :derivative_of, :name, :nature, :reference_name,
           to: :variant, prefix: true
  delegate :unit_name, :france_maaid, to: :variant
  delegate :able_to_each?, :able_to?, :of_expression, :subscribing?,
           :deliverable?, :asset_account, :product_account, :charge_account,
           :stock_account, :population_counting, :population_counting_unitary?,
           :identifiable?,
           to: :nature
  delegate :has_indicator?, :individual_indicators_list, :whole_indicators_list,
           :abilities, :abilities_list, :indicators, :indicators_list,
           :frozen_indicators, :frozen_indicators_list, :variable_indicators,
           :variable_indicators_list, :linkage_points, :linkage_points_list,
           to: :nature

  after_initialize :choose_default_name
  after_save :set_initial_values, if: :initializeable?

  before_validation do
    self.initial_born_at ||= Time.zone.now
    self.born_at ||= self.initial_born_at
    self.initial_born_at = self.born_at
    self.initial_dead_at = dead_at
    self.uuid ||= UUIDTools::UUID.random_create.to_s
    # self.net_surface_area = initial_shape.area.in(:hectare).round(3)
  end

  before_validation :set_default_values, on: :create
  before_validation :update_default_values, on: :update

  after_validation do
    self.born_at ||= self.initial_born_at
    self.dead_at ||= initial_dead_at
    self.default_storage ||= initial_container
    self.initial_container ||= self.default_storage
  end

  validate do
    if nature && variant
      errors.add(:nature_id, :invalid) if variant.nature_id != nature_id
    end
    if dead_at && born_at
      errors.add(:dead_at, :invalid) if dead_at < born_at
    end
    if variant
      if variety && Nomen::Variety.find(variant_variety)
        unless Nomen::Variety.find(variant_variety) >= variety
          errors.add(:variety, :invalid)
        end
      end
      if derivative_of && Nomen::Variety.find(variant_derivative_of)
        unless Nomen::Variety.find(variant_derivative_of) >= derivative_of
          errors.add(:derivative_of, :invalid)
        end
      end
    end
  end

  protect(on: :destroy) do
    analyses.any? || intervention_product_parameters.any? || issues.any? || parcel_items.any?
  end

  class << self
    # Auto-cast product to best matching class with type column
    def new_with_cast(*attributes, &block)
      if (h = attributes.first).is_a?(Hash) && !h.nil? && (type = h[:type] || h['type']) && !type.empty? && (klass = type.constantize) != self
        raise "Can not cast #{name} to #{klass.name}" unless klass <= self
        return klass.new(*attributes, &block)
      end
      new_without_cast(*attributes, &block)
    end
    alias_method_chain :new, :cast

    def miscibility_of(products_and_variants)
      PhytosanitaryMiscibility.new(products_and_variants).legality
    end
  end

  def production(_at = nil)
    activity_production
  end

  def activity
    production ? production.activity : nil
  end

  def activity_id
    activity ? activity.id : nil
  end

  def best_activity_production(_options = {})
    activity_production
  end

  # TODO: Removes this ASAP
  def deliverable?
    false
  end

  def available?
    dead_at.nil? && !population.zero?
  end

  def nature_name
    nature ? nature.name : nil
  end

  def work_name
    if work_number.present?
      # FIXME: Not I18nized
      name.to_s + ' (' + work_number.to_s + ')'
    elsif identification_number.present?
      # FIXME: Not I18nized
      name.to_s + ' (' + identification_number.to_s + ')'
    else
      name
    end
  end

  def unroll_name
    'unrolls.backend/products'.t(attributes.symbolize_keys.merge(population: population, unit_name: unit_name))
  end

  # set initial owner and localization
  # after_save
  def set_initial_values
    # Add first owner on a product
    ownership = ownerships.first_of_all || ownerships.build
    ownership.owner = initial_owner
    ownership.save!

    # Add first enjoyer on a product
    enjoyment = enjoyments.first_of_all || enjoyments.build
    enjoyment.enjoyer = initial_enjoyer || initial_owner
    enjoyment.save!

    # Add first localization on a product
    localization = localizations.first_of_all || localizations.build
    localization.container = self.initial_container
    localization.save!

    if born_at
      # Configure initial_movement
      movement = initial_movement || build_initial_movement
      movement.product = self
      movement.delta = !!initial_population && variant.population_counting_unitary? ? 1 : initial_population
      movement.started_at = born_at
      movement.save!
      update_column(:initial_movement_id, movement.id)

      # Initial shape
      if initial_shape && variable_indicators_list.include?(:shape)
        reading = initial_reading(:shape) || readings.new(indicator_name: :shape)
        reading.value = initial_shape
        reading.read_at = born_at
        reading.save!
        ProductReading.destroy readings.where.not(id: reading.id).where(indicator_name: :shape, read_at: reading.read_at).pluck(:id)
      end
    end

    # Add first frozen indicator on a product from his variant
    if variant
      phase = phases.first_of_all || phases.build
      phase.variant = variant
      phase.save!
      # set indicators from variant in products readings
      variant.readings.each do |variant_reading|
        reading = readings.first_of_all(variant_reading.indicator_name) ||
                  readings.new(indicator_name: variant_reading.indicator_name)
        reading.value = variant_reading.value
        reading.read_at = born_at
        reading.save!
      end
    end
  end

  def shape=(new_shape)
    reading_cache[:shape] = new_shape
    reading_cache[:net_surface_area] = calculate_net_surface_area

    shape
  end

  # Try to find the best name for the new products
  def choose_default_name
    return if name.present?
    if variant
      if last = variant.products.reorder(id: :desc).first
        self.name = last.name
        array = name.split(/\s+/)
        if array.last =~ /^\(+\d+\)+?$/
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

  # Sets nature and variety from variant
  def set_default_values
    if variant
      self.nature_id = variant.nature_id
      self.variety ||= variant.variety
      if derivative_of.blank? && variant.derivative_of.present?
        self.derivative_of = variant.derivative_of
      end
    end
    self.category_id = nature.category_id if nature
  end

  # Update nature and variety and variant from phase
  def update_default_values
    if current_phase
      phase_variant = current_phase.variant
      return if phase_variant.nil?
      self.nature_id = phase_variant.nature_id
      self.variety ||= phase_variant.variety
      if derivative_of.blank? && !phase_variant.derivative_of.nil?
        self.derivative_of = phase_variant.derivative_of
      end
    end
    self.category_id = nature.category_id if nature
  end

  def initial_reading(indicator_name)
    first_reading(indicator_name)
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

  # Returns item from default catalog for given usage
  def default_catalog_item(usage)
    return nil unless variant
    variant.default_catalog_item(usage)
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

    price = if incoming_purchase_item
              # search a price in purchase item via incoming item price
              incoming_purchase_item.unit_pretax_amount
            elsif outgoing_sale_item
              # search a price in sale item via outgoing item price
              outgoing_sale_item.unit_pretax_amount
            elsif catalog_item = variant.catalog_items.limit(1).first
              # search a price in catalog price
              if catalog_item.all_taxes_included == true
                catalog_item.reference_tax.pretax_amount_of(catalog_item.amount)
              else
                catalog_item.amount
              end
            end
    price
  end

  def dead?
    dead_at.present?
  end

  def dead_first_at
    list = issues.where(dead: true).order(:observed_at).limit(1).pluck(:observed_at) +
           intervention_product_parameters.where(dead: true).joins(:intervention).order('interventions.stopped_at').limit(1).pluck('interventions.stopped_at')
    list.any? ? list.min : nil
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
    pops = populations.last_before(options[:at] || Time.zone.now)
    return 0.0 if pops.none?
    pops.first.value
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

  Nomen::Indicator.each do |indicator|
    alias_method :"cache_#{indicator}", indicator

    define_method indicator.to_sym do |*args|
      return get(indicator, *args) if args.present?
      send(:"cache_#{indicator}")
    end

    define_method :"#{indicator}!" do |*args|
      return get!(indicator, *args) if args.present?
      send(:"cache_#{indicator}")
    end
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
    new_record? || !(parcel_items.any? || InterventionParameter.of_generic_roles(%i[input output target doer tool]).of_actor(self).any? || fixed_assets.any?)
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
      next if variable.abilities.detect { |a| !able_to?(a) }
      list << variable
    end
    list
  end

  def net_surface_area
    computed_surface = reading_cache[:net_surface_area] || reading_cache['net_surface_area']
    return computed_surface if computed_surface
    calculated = calculate_net_surface_area
    update(reading_cache: reading_cache.merge(net_surface_area: calculated))
    self.net_surface_area = calculated
  end

  # Override net_surface_area indicator to compute it from shape if
  # product has shape indicator unless options :strict is given
  def calculate_net_surface_area(options = {})
    # TODO: Manage global preferred surface unit or system
    area_unit = options[:unit] || :hectare
    if !options.keys.detect { |k| %i[gathering interpolate cast].include?(k) } &&
       has_indicator?(:shape) && !options[:compute].is_a?(FalseClass)
      unless options[:strict]
        options[:at] = born_at if born_at && born_at > Time.zone.now
      end
      shape = get(:shape, options)
      area = shape.area.in(:square_meter).in(area_unit).round(3) if shape
    else
      area = get(:net_surface_area, options)
    end
    area || 0.in(area_unit)
  end

  def initial_shape_area
    ::Charta.new_geometry(initial_shape).area.in_square_meter
  end

  def get(indicator, *args)
    return super if args.any?(&:present?)
    in_cache = reading_cache[indicator.to_s]
    return in_cache if in_cache
    indicator_value = super
    reading_cache[indicator.to_s] = indicator_value
    unless new_record?
      update_column(:reading_cache, reading_cache.merge(indicator.to_s => indicator_value))
    end
    indicator_value
  end
end
