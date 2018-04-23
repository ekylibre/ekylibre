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
# == Table: activity_productions
#
#  activity_id         :integer          not null
#  campaign_id         :integer
#  created_at          :datetime         not null
#  creator_id          :integer
#  cultivable_zone_id  :integer
#  custom_fields       :jsonb
#  id                  :integer          not null, primary key
#  irrigated           :boolean          default(FALSE), not null
#  lock_version        :integer          default(0), not null
#  nitrate_fixing      :boolean          default(FALSE), not null
#  rank_number         :integer          not null
#  season_id           :integer
#  size_indicator_name :string           not null
#  size_unit_name      :string
#  size_value          :decimal(19, 4)   not null
#  started_on          :date
#  state               :string
#  stopped_on          :date
#  support_id          :integer          not null
#  support_nature      :string
#  support_shape       :geometry({:srid=>4326, :type=>"multi_polygon"})
#  tactic_id           :integer
#  updated_at          :datetime         not null
#  updater_id          :integer
#  usage               :string           not null
#

class ActivityProduction < Ekylibre::Record::Base
  include Attachable
  include Customizable

  enumerize :support_nature, in: %i[cultivation fallow_land buffer border none animal_group], default: :cultivation
  refers_to :usage, class_name: 'ProductionUsage'
  refers_to :size_indicator, class_name: 'Indicator'
  refers_to :size_unit, class_name: 'Unit'
  belongs_to :activity, inverse_of: :productions
  belongs_to :campaign
  belongs_to :cultivable_zone
  belongs_to :support, class_name: 'Product' # , inverse_of: :supports
  belongs_to :tactic, class_name: 'ActivityTactic', inverse_of: :productions
  belongs_to :season, class_name: 'ActivitySeason', inverse_of: :productions
  has_many :products
  has_many :budgets, through: :activity
  has_many :manure_management_plan_zones, class_name: 'ManureManagementPlanZone',
                                          inverse_of: :activity_production
  has_one :selected_manure_management_plan_zone, -> { selecteds },
          class_name: 'ManureManagementPlanZone', inverse_of: :activity_production
  has_one :cap_land_parcel, class_name: 'CapLandParcel', inverse_of: :activity_production, foreign_key: :support_id

  has_and_belongs_to_many :interventions
  has_and_belongs_to_many :campaigns

  has_geometry :support_shape
  composed_of :size, class_name: 'Measure', mapping: [%w[size_value to_d], %w[size_unit_name unit]]

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :irrigated, :nitrate_fixing, inclusion: { in: [true, false] }
  validates :rank_number, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :activity, :size_indicator_name, :support, :usage, presence: true
  validates :size_value, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :started_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :state, length: { maximum: 500 }, allow_blank: true
  validates :stopped_on, timeliness: { on_or_after: ->(activity_production) { activity_production.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]
  validates :rank_number, uniqueness: { scope: :activity_id }
  validates :started_on, presence: true
  # validates_presence_of :cultivable_zone, :support_nature, if: :plant_farming?
  validates :support_nature, presence: { if: :plant_farming? }
  validates :campaign, :stopped_on, presence: { if: :annual? }
  validates :started_on, presence: true
  # validates_numericality_of :size_value, greater_than: 0
  # validates_presence_of :size_unit, if: :size_value?

  delegate :name, :work_number, to: :support, prefix: true
  # delegate :shape, :shape_to_ewkt, :shape_svg, :net_surface_area, :shape_area, to: :support
  delegate :name, :size_indicator_name, :size_unit_name, to: :activity, prefix: true
  delegate :animal_farming?, :plant_farming?, :tool_maintaining?,
           :at_cycle_start?, :at_cycle_end?, :use_seasons?, :use_tactics?,
           :with_cultivation, :cultivation_variety, :with_supports, :support_variety,
           :color, :annual?, :perennial?, to: :activity

  scope :of_campaign, lambda { |campaign|
    where(id: HABTM_Campaigns.select(:activity_production_id).where(campaign: campaign))
  }

  scope :of_cultivation_variety, lambda { |variety|
    where(activity: Activity.of_cultivation_variety(variety))
  }
  scope :of_current_campaigns, -> {
    of_campaign(Campaign.current.last)
  }

  scope :of_activity, ->(activity) { where(activity: activity) }
  scope :of_activities, lambda { |*activities|
    where(activity_id: activities.flatten.map(&:id))
  }
  scope :of_activity_families, lambda { |*families|
    where(activity: Activity.of_families(*families))
  }

  scope :of_crumbs, lambda { |*crumbs|
    options = crumbs.extract_options!
    options[:campaigns] ||= Campaign.current

    of_campaign(options[:campaigns].first).distinct
                                          .joins(:support)
                                          .joins('INNER JOIN crumbs ON ST_Contains(ST_CollectionExtract(activity_productions.support_shape, 3), crumbs.geolocation)')
                                          .where(crumbs.any? ? ['crumbs.id IN (?)', crumbs.flatten.map(&:id)] : 'crumbs.id IS NOT NULL')
  }

  scope :at, ->(at) { where(':now BETWEEN COALESCE(started_on, :now) AND COALESCE(stopped_on, :now)', now: at.to_date) }
  scope :current, -> { at(Time.zone.now) }

  state_machine :state, initial: :opened do
    state :opened
    state :aborted
    state :closed

    event :abort do
      transition opened: :aborted
    end

    event :close do
      transition opened: :closed
    end

    event :reopen do
      transition closed: :opened
      transition aborted: :opened
    end
  end

  before_validation on: :create do
    if activity
      self.rank_number = (activity.productions.maximum(:rank_number) ? activity.productions.maximum(:rank_number) : 0) + 1
    end
    true
  end

  before_validation do
    self.started_on ||= Date.today
    self.usage = Nomen::ProductionUsage.first unless usage
    if activity
      self.stopped_on ||= self.started_on + 1.year - 1.day if annual?
      self.size_indicator_name ||= activity_size_indicator_name if activity_size_indicator_name
      self.size_unit_name = activity_size_unit_name
      self.rank_number ||= (activity.productions.maximum(:rank_number) ? activity.productions.maximum(:rank_number) : 0) + 1
      if valid_period_for_support?
        if plant_farming?
          initialize_land_parcel_support!
        elsif animal_farming?
          initialize_animal_group_support!
        elsif tool_maintaining?
          initialize_equipment_fleet_support!
        end
      end
    end
    true
  end

  before_validation(on: :create) do
    self.state ||= :opened
    true
  end

  validate do
    if plant_farming?
      errors.add(:support_shape, :empty) if support_shape && support_shape.empty?
    end
    true
  end

  after_save do
    support.update(activity_production: self) if support
  end

  after_commit do
    if activity.productions.where(rank_number: rank_number).count > 1
      update_column(:rank_number, activity.productions.maximum(:rank_number) + 1)
    end
    Ekylibre::Hook.publish(:activity_production_change, activity_production_id: id)
  end

  after_destroy do
    support.destroy if support.is_a?(LandParcel) && support.activity_productions.empty?

    Ekylibre::Hook.publish(:activity_production_destroy, activity_production_id: id)
  end

  protect(on: :destroy) do
    interventions.any?
  end

  def computed_support_name
    list = []
    list << cultivable_zone.name if cultivable_zone
    list << activity.name
    list << campaign.name if campaign
    list << :rank.t(number: rank_number)
    list.reverse! if 'i18n.dir'.t == 'rtl'
    list.join(' ')
  end

  def interventions_of_nature(nature)
    interventions
      .where(nature: nature)
  end

  def update_names
    if support
      new_support_name = computed_support_name
      if support.name != new_support_name
        support.update_column(:name, new_support_name)
      end
    end
  end

  def valid_period_for_support?
    if self.started_on
      return false if self.started_on < Time.new(1, 1, 1).in_time_zone
    end
    if self.stopped_on
      return false if self.stopped_on >= Time.zone.now + 50.years
    end
    if self.started_on && self.stopped_on
      return false if self.started_on > self.stopped_on
    end
    true
  end

  def initialize_land_parcel_support!
    self.support_shape ||= cultivable_zone.shape if cultivable_zone
    unless support
      if self.support_shape
        land_parcels = LandParcel.shape_matching(self.support_shape)
                                 .where.not(id: ActivityProduction.select(:support_id))
                                 .order(:id)
        self.support = land_parcels.first if land_parcels.any?
      end
      self.support ||= LandParcel.new
    end
    support.name = name
    support.initial_shape = self.support_shape
    support.initial_born_at = started_on
    support.initial_dead_at = stopped_on
    support.born_at = started_on
    support.dead_at = stopped_on
    support.variant ||= ProductNatureVariant.import_from_nomenclature(:land_parcel)
    support.save!
    reading = support.first_reading(:shape)
    if reading
      reading.value = self.support_shape
      reading.read_at = support.born_at
      reading.save!
    end
    self.size = support_shape_area.in(size_unit_name)
  end

  def initialize_animal_group_support!
    unless support
      self.support = AnimalGroup.new
      support.name = computed_support_name
    end
    # FIXME: Need to find better category and population_counting...
    unless support.variant
      nature = ProductNature.find_or_create_by!(
        variety: :animal_group,
        derivative_of: :animal,
        name: AnimalGroup.model_name.human,
        category: ProductNatureCategory.import_from_nomenclature(:cattle_herd),
        population_counting: :unitary
      )
      variant = ProductNatureVariant.find_or_initialize_by(
        nature: nature,
        variety: :animal_group,
        derivative_of: :animal
      )
      variant.name ||= nature.name
      variant.unit_name ||= :unit.tl
      variant.save! if variant.new_record?
      support.variant = variant
    end
    if activity.cultivation_variety
      support.derivative_of ||= activity.cultivation_variety
    end
    support.save!
    if size_value.nil?
      errors.add(:size_value, :empty)
    else
      self.size = size_value.in(size_unit_name)
    end
  end

  def initialize_equipment_fleet_support!
    self.support = EquipmentFleet.new unless support
    support.name = computed_support_name
    # FIXME: Need to find better category and population_counting...
    unless support.variant
      nature = ProductNature.find_or_create_by!(
        variety: :equipment_fleet,
        derivative_of: :equipment,
        name: EquipmentFleet.model_name.human,
        category: ProductNatureCategory.import_from_nomenclature(:equipment_fleet),
        population_counting: :unitary
      )
      variant = ProductNatureVariant.find_or_initialize_by(
        nature: nature,
        variety: :equipment_fleet,
        derivative_of: :equipment
      )
      variant.name ||= nature.name
      variant.unit_name ||= :unit.tl
      variant.save! if variant.new_record?
      support.variant = variant
    end
    if activity.cultivation_variety
      support.derivative_of ||= activity.cultivation_variety
    end
    support.save!
    if size_value.nil?
      errors.add(:size_value, :empty)
    else
      self.size = size_value.in(size_unit_name)
    end
  end

  def active?
    activity.family.to_s != 'fallow_land'
  end

  def season?
    !season_id.nil?
  end

  def interventions_by_weeks
    interventions_by_week = {}
    interventions.each do |intervention|
      week_number = intervention.started_at.to_date.cweek
      interventions_by_week[week_number] ||= []
      interventions_by_week[week_number] << intervention
    end
    interventions_by_week
  end

  def started_on_for(campaign)
    return self.started_on if annual?
    on = begin
           Date.civil(campaign.harvest_year, self.started_on.month, self.started_on.day)
         rescue
           Date.civil(campaign.harvest_year, self.started_on.month, self.started_on.day - 1)
         end
    on -= 1.year if at_cycle_end?
    on
  end

  def stopped_on_for(campaign)
    return stopped_on if annual?
    on = Date.civil(campaign.harvest_year, self.started_on.month, self.started_on.day) - 1
    on += 1.year if at_cycle_start?
    on
  end

  # Used for find current campaign for given production
  def current_campaign
    Campaign.at(Time.zone.now).first
  end

  def cost(role = :input)
    costs = interventions.collect do |intervention|
      intervention.cost(role)
    end
    costs.compact.sum
  end

  # Returns the spreaded quantity of one chemicals components (N, P, K) per area unit
  # Get all intervention of category 'fertilizing' and sum all indicator unity spreaded
  #  - indicator could be (:potassium_concentration, :nitrogen_concentration, :phosphorus_concentration)
  #  - area_unit could be (:hectare, :square_meter)
  #  - from and to used to select intervention
  def soil_enrichment_indicator_content_per_area(indicator_name, from = nil, to = nil, area_unit_name = :hectare)
    balance = []
    procedure_category = :fertilizing
    interventions = if from && to
                      self.interventions.real.of_category(procedure_category).between(from, to)
                    else
                      self.interventions.real.of_category(procedure_category)
                    end
    interventions.each do |intervention|
      intervention.inputs.each do |input|
        # m = net_mass of the input at intervention time
        # n = indicator (in %) of the input at intervention time
        m = (input.actor ? input.actor.net_mass(input).to_d(:kilogram) : 0.0)
        # TODO: for method phosphorus_concentration(input)
        n = (input.actor ? input.actor.send(indicator_name).to_d(:unity) : 0.0)
        balance << m * n
      end
    end
    # if net_surface_area, make the division
    area = net_surface_area.to_d(area_unit_name)
    indicator_unity_per_hectare = balance.compact.sum / area if area.nonzero?
    indicator_unity_per_hectare
  end

  # TODO: for nitrogen balance but will be refactorize for any chemical components
  def nitrogen_balance
    # B = O - I
    balance = 0.0
    nitrogen_mass = []
    nitrogen_unity_per_hectare = nil
    if selected_manure_management_plan_zone
      # get the output O aka nitrogen_input from opened_at (in kg N / Ha )
      o = selected_manure_management_plan_zone.nitrogen_input || 0.0
      # get the nitrogen input I from opened_at to now (in kg N / Ha )
      opened_at = selected_manure_management_plan_zone.opened_at
      i = soil_enrichment_indicator_content_per_area(:nitrogen_concentration, opened_at, Time.zone.now)
      balance = o - i if i && o
    else
      balance = soil_enrichment_indicator_content_per_area(:nitrogen_concentration)
    end
    balance
  end

  def potassium_balance
    soil_enrichment_indicator_content_per_area(:potassium_concentration)
  end

  def phosphorus_balance
    soil_enrichment_indicator_content_per_area(:phosphorus_concentration)
  end

  def provisional_nitrogen_input
    0
  end

  def tool_cost(surface_unit_name = :hectare)
    surface_area = net_surface_area
    if surface_area.to_s.to_f > 0.0
      return cost(:tool) / surface_area.to_d(surface_unit_name).to_s.to_f
    end
    0.0
  end

  def input_cost(surface_unit_name = :hectare)
    surface_area = net_surface_area
    if surface_area.to_s.to_f > 0.0
      return cost(:input) / surface_area.to_d(surface_unit_name).to_s.to_f
    end
    0.0
  end

  def time_cost(surface_unit_name = :hectare)
    surface_area = net_surface_area
    if surface_area.to_s.to_f > 0.0
      return cost(:doer) / surface_area.to_d(surface_unit_name).to_s.to_f
    end
    0.0
  end

  # Returns all plants concerning by this activity production
  # TODO: No plant here, a more generic method should be largely preferable
  def inside_plants
    inside_products(Plant)
  end

  def inside_products(products = Product)
    products = if campaign
                 products.of_campaign(campaign)
               else
                 products.where(born_at: started_on..(stopped_on || Time.zone.now.to_date))
               end
    products.shape_within(support_shape)
  end

  # Returns the started_at attribute of the intervention of nature sowing if
  # exist and if it's a vegetal activity
  def implanted_at
    intervention = interventions.real.of_category(:planting).first
    return intervention.started_at if intervention
    nil
  end

  # Returns the started_at attribute of the intervention of nature harvesting
  # if exist and if it's a vegetal activity
  def harvested_at
    intervention = interventions.real.of_category(:harvesting).first
    return intervention.started_at if intervention
    nil
  end

  # Generic method to get harvest yield
  def harvest_yield(harvest_variety, options = {})
    size_indicator_name = options[:size_indicator_name] || :net_mass
    ind = Nomen::Indicator.find(size_indicator_name)
    raise "Invalid indicator: #{size_indicator_name}" unless ind
    size_unit_name = options[:size_unit_name] || ind.unit
    unless Nomen::Unit.find(size_unit_name)
      raise "Invalid indicator unit: #{size_unit_name.inspect}"
    end
    surface_unit_name = options[:surface_unit_name] || :hectare
    procedure_category = options[:procedure_category] || :harvesting
    surface = net_surface_area
    unless surface && surface.to_d > 0
      Rails.logger.warn 'No surface area. Cannot compute harvest yield'
      return nil
    end
    harvest_yield_unit_name = "#{size_unit_name}_per_#{surface_unit_name}".to_sym
    unless Nomen::Unit.find(harvest_yield_unit_name)
      raise "Harvest yield unit doesn't exist: #{harvest_yield_unit_name.inspect}"
    end
    total_quantity = 0.0.in(size_unit_name)

    target_distribution_plants = Plant.where(activity_production: self)

    # get harvest_interventions firstly by distributions and secondly by inside_plants method
    harvest_interventions = Intervention.real.of_category(procedure_category).with_targets(target_distribution_plants) if target_distribution_plants.any?
    harvest_interventions ||= Intervention.real.of_category(procedure_category).with_targets(inside_plants)

    coef_area = []
    global_coef_harvest_yield = []

    if harvest_interventions.any?
      harvest_interventions.includes(:targets).find_each do |harvest|
        harvest_working_area = []
        harvest.targets.each do |target|
          if zone = target.working_zone
            harvest_working_area << ::Charta.new_geometry(zone).area.in(:square_meter)
          end
        end
        harvest.outputs.each do |cast|
          actor = cast.product
          next unless actor && actor.variety
          variety = Nomen::Variety.find(actor.variety)
          if variety && variety <= harvest_variety
            quantity = cast.quantity_population.in(actor.variant.send(size_indicator_name).unit)
            total_quantity += quantity.convert(size_unit_name) if quantity
          end
        end
        h = harvest_working_area.compact.sum.to_d.in(surface_unit_name).to_f
        if h && h > 0.0
          global_coef_harvest_yield << (h * (total_quantity.to_f / h))
          coef_area << h
        end
      end
    end

    total_weighted_average_harvest_yield = global_coef_harvest_yield.compact.sum / coef_area.compact.sum if coef_area.compact.sum.to_d != 0.0
    Measure.new(total_weighted_average_harvest_yield.to_f, harvest_yield_unit_name)
  end

  # Returns the yield of grain in mass per surface unit
  def grains_yield(mass_unit_name = :quintal, surface_unit_name = :hectare)
    harvest_yield(:grain, procedure_category: :harvesting,
                          size_indicator_name: :net_mass,
                          size_unit_name: mass_unit_name,
                          surface_unit_name: surface_unit_name)
  end

  # Returns the yield of grape in volume per surface unit
  def vine_yield(volume_unit_name = :hectoliter, surface_unit_name = :hectare)
    harvest_yield(:grape, procedure_category: :harvesting,
                          size_indicator_name: :net_volume,
                          size_unit_name: volume_unit_name,
                          surface_unit_name: surface_unit_name)
  end

  # TODO: Which yield is computed? usage is not very good to determine yields
  #   because many yields can be computed...
  def estimate_yield(campaign, options = {})
    variety = options.delete(:variety)
    # compute variety for estimate yield
    if usage == 'grain' || usage == 'seed'
      variety ||= 'grain'
    elsif usage == 'fodder' || usage == 'fiber'
      variety ||= 'grass'
    end
    # get current campaign
    budget = activity.budget_of(campaign)
    return nil unless budget
    budget.estimate_yield(variety, options)
  end

  def current_cultivation
    # get the first object with variety 'plant', availables
    if cultivation = support.contents.where(type: Plant).of_variety(variant.variety).availables.reorder(:born_at).first
      cultivation
    end
  end

  def unified_size_unit
    size_unit_name.blank? ? :unity : size_unit_name
  end

  # Compute quantity of a support as defined in production
  def current_size(options = {})
    options[:at] ||= self.started_on ? self.started_on.to_time : Time.zone.now
    value = support.get(size_indicator_name, options)
    value = value.in(size_unit_name) if size_unit_name.present?
    value
  end

  def duplicate!(updates = {})
    new_attributes = %i[
      activity campaign cultivable_zone irrigated nitrate_fixing
      size_indicator_name size_unit_name size_value started_on
      support_nature support_shape usage
    ].each_with_object({}) do |attr, h|
      h[attr] = send(attr)
      h
    end.merge(updates)
    self.class.create!(new_attributes)
  end

  alias net_surface_area support_shape_area

  ## LABEL METHODS ##

  def work_name
    "#{support_work_number} - #{net_surface_area.convert(:hectare).round(2)}"
  end

  # Returns unique i18nized name for given production
  def name(options = {})
    list = []
    list << activity.name unless options[:activity].is_a?(FalseClass)
    list << season.name if season.present?
    list << cultivable_zone.name if cultivable_zone && plant_farming?
    list << started_on.to_date.l(format: :month) if activity.annual? && started_on
    list << :rank.t(number: rank_number)
    list = list.reverse! if 'i18n.dir'.t == 'rtl'
    list.join(' ')
  end

  def get(*args)
    if support.blank?
      raise StandardError, "No support defined. Got: #{support.inspect}"
    end
    support.get(*args)
  end

  # # Returns value of an indicator if its name correspond to
  # def method_missing(method_name, *args)
  #   if Nomen::Indicator.include?(method_name.to_s)
  #     return get(method_name, *args)
  #   end
  #   super
  # end
end
