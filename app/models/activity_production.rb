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
#  size_indicator_name :string           not null
#  size_unit_name      :string
#  size_value          :decimal(19, 4)   not null
#  started_on          :date
#  state               :string
#  stopped_on          :date
#  support_id          :integer          not null
#  support_nature      :string
#  support_shape       :geometry({:srid=>4326, :type=>"multi_polygon"})
#  updated_at          :datetime         not null
#  updater_id          :integer
#  usage               :string           not null
#

class ActivityProduction < Ekylibre::Record::Base
  include Customizable
  enumerize :support_nature, in: [:cultivation, :fallow_land, :buffer, :border, :none], default: :cultivation
  refers_to :usage, class_name: 'ProductionUsage'
  refers_to :size_indicator, class_name: 'Indicator'
  refers_to :size_unit, class_name: 'Unit'
  belongs_to :activity, inverse_of: :productions
  belongs_to :campaign
  belongs_to :cultivable_zone
  belongs_to :support, class_name: 'Product' # , inverse_of: :supports
  has_many :distributions, class_name: 'TargetDistribution', inverse_of: :activity_production
  has_many :budgets, through: :activity
  has_many :manure_management_plan_zones, class_name: 'ManureManagementPlanZone',
                                          inverse_of: :activity_production
  has_one :selected_manure_management_plan_zone, -> { selecteds },
          class_name: 'ManureManagementPlanZone', inverse_of: :activity_production
  has_one :cap_land_parcel, class_name: 'CapLandParcel', inverse_of: :activity_production, foreign_key: :support_id

  has_geometry :support_shape
  composed_of :size, class_name: 'Measure', mapping: [%w(size_value to_d), %w(size_unit_name unit)]

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_date :started_on, :stopped_on, allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }
  validates_datetime :stopped_on, allow_blank: true, on_or_after: :started_on, if: ->(activity_production) { activity_production.stopped_on && activity_production.started_on }
  validates_numericality_of :rank_number, allow_nil: true, only_integer: true
  validates_numericality_of :size_value, allow_nil: true
  validates_inclusion_of :irrigated, :nitrate_fixing, in: [true, false]
  validates_presence_of :activity, :rank_number, :size_indicator_name, :size_value, :support, :usage
  # ]VALIDATORS]
  validates_uniqueness_of :rank_number, scope: :activity_id
  validates_presence_of :started_on
  # validates_presence_of :cultivable_zone, :support_nature, if: :plant_farming?
  validates_presence_of :support_nature, if: :plant_farming?
  validates_presence_of :campaign, :stopped_on, if: :annual?
  validates_presence_of :started_on
  # validates_numericality_of :size_value, greater_than: 0
  # validates_presence_of :size_unit, if: :size_value?

  delegate :name, :work_number, to: :support, prefix: true
  # delegate :shape, :shape_to_ewkt, :shape_svg, :net_surface_area, :shape_area, to: :support
  delegate :name, :size_indicator_name, :size_unit_name, to: :activity, prefix: true
  delegate :animal_farming?, :plant_farming?,
           :at_cycle_start?, :at_cycle_end?,
           :with_cultivation, :cultivation_variety, :with_supports, :support_variety,
           :color, :annual?, :perennial?, to: :activity

  scope :of_campaign, lambda { |campaign|
    where('campaign_id = ?' \
          ' OR campaign_id IS NULL AND (' \
          "activity_productions.id IN (SELECT ap.id FROM activity_productions AS ap JOIN activities AS a ON a.id = ap.activity_id, campaigns AS c WHERE a.production_cycle = 'perennial' AND a.production_campaign = 'at_cycle_start' AND c.id = ? AND ((ap.stopped_on is null AND c.harvest_year >= EXTRACT(YEAR FROM ap.started_on)) OR (ap.stopped_on is not null AND EXTRACT(YEAR FROM ap.started_on) <= c.harvest_year AND c.harvest_year < EXTRACT(YEAR FROM ap.stopped_on))))" \
          " OR activity_productions.id IN (SELECT ap.id FROM activity_productions AS ap JOIN activities AS a ON a.id = ap.activity_id, campaigns AS c WHERE a.production_cycle = 'perennial' AND a.production_campaign = 'at_cycle_end' AND c.id = ? AND ((ap.stopped_on is null AND c.harvest_year > EXTRACT(YEAR FROM ap.started_on)) OR (ap.stopped_on is not null AND EXTRACT(YEAR FROM ap.started_on) < c.harvest_year AND c.harvest_year <= EXTRACT(YEAR FROM ap.stopped_on))))" \
          ')', campaign.id, campaign.id, campaign.id)
  }

  scope :of_cultivation_variety, lambda { |variety|
    where(activity: Activity.of_cultivation_variety(variety))
  }
  scope :of_current_campaigns, -> { of_campaign(Campaign.current.last) }

  scope :of_activity, ->(activity) { where(activity: activity) }
  scope :of_activities, lambda { |*activities|
    where(activity_id: activities.flatten.map(&:id))
  }
  scope :of_activity_families, lambda { |*families|
    where(activity: Activity.of_families(*families))
  }
  scope :current, -> { where(':now BETWEEN COALESCE(started_on, :now) AND COALESCE(stopped_on, :now)', now: Time.zone.now) }

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
    if self.activity
      self.rank_number = (self.activity.productions.maximum(:rank_number) ? self.activity.productions.maximum(:rank_number) : 0) + 1
    end
  end

  before_validation do
    self.started_on ||= Date.today
    self.usage = Nomen::ProductionUsage.first unless usage
    if self.activity
      self.stopped_on ||= self.started_on + 1.year - 1.day if annual?
      self.size_indicator_name ||= activity_size_indicator_name if activity_size_indicator_name
      self.size_unit_name = activity_size_unit_name
      self.rank_number ||= (self.activity.productions.maximum(:rank_number) ? self.activity.productions.maximum(:rank_number) : 0) + 1
      if plant_farming?
        self.support_shape ||= cultivable_zone.shape if cultivable_zone
        if support_shape && !support
          land_parcels = LandParcel.shape_matching(support_shape)
                                   .where.not(id: ActivityProduction.select(:support_id))
                                   .order(:id)
          self.support = land_parcels.any? ? land_parcels.first : LandParcel.new
          support.name = computed_support_name
          support.initial_shape = support_shape
          support.initial_born_at = started_on
          support.variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
          support.save!
        end
        self.size = support_shape_area.in(size_unit_name)
      elsif animal_farming?
        unless support
          self.support = AnimalGroup.new
          support.name = computed_support_name
          # FIXME: Need to find better category and population_counting...
          nature = ProductNature.find_or_create_by!(variety: :animal_group, derivative_of: :animal, name: AnimalGroup.model_name.human, category: ProductNatureCategory.import_from_nomenclature(:cattle_herd), population_counting: :unitary)
          variant = ProductNatureVariant.find_or_initialize_by(nature: nature, variety: :animal_group, derivative_of: :animal)
          variant.name ||= nature.name
          variant.unit_name ||= :unit.tl
          variant.save! if variant.new_record?
          support.variant = variant
          support.derivative_of = self.activity.cultivation_variety
          support.save!
        end
        if size_value.nil?
          errors.add(:size_value, :empty)
        else
          self.size = size_value.in(size_unit_name)
        end
      end
    end
  end

  before_validation(on: :create) do
    self.state ||= :opened
  end

  validate do
    if plant_farming?
      errors.add(:support_shape, :empty) if self.support_shape && self.support_shape.empty?
    end
  end

  before_update do
    # self.support.name = computed_support_name
    support.initial_born_at = started_on
    if old_record.support_shape != self.support_shape
      support.initial_shape = support_shape
      if self.support_shape
        # TODO: Update only very first shape reading
        support.read!(:shape, self.support_shape, at: started_on)
      end
    end
    support.save!
  end

  after_commit do
    if self.activity.productions.where(rank_number: rank_number).count > 1
      update_column(:rank_number, self.activity.productions.maximum(:rank_number) + 1)
    end
    Ekylibre::Hook.publish(:activity_production_change, activity_production_id: id)
  end

  after_destroy do
    Ekylibre::Hook.publish(:activity_production_destroy, activity_production_id: id)
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

  def update_names
    if support
      new_support_name = computed_support_name
      if support.name != new_support_name
        support.update_column(:name, new_support_name)
      end
    end
  end

  def active?
    activity.family.to_s != 'fallow_land'
  end

  # Returns interventions of current production
  def interventions
    Intervention.of_activity_production(self)
  end

  def campaigns
    Campaign.of_activity_production(self)
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
    indicator_unity_per_hectare = balance.compact.sum / area if area != 0
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
    if net_surface_area.to_s.to_f > 0.0
      return cost(:tool) / net_surface_area.to_d(surface_unit_name).to_s.to_f
    end
    0.0
  end

  def input_cost(surface_unit_name = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:input) / net_surface_area.to_d(surface_unit_name).to_s.to_f
    end
    0.0
  end

  def time_cost(surface_unit_name = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:doer) / net_surface_area.to_d(surface_unit_name).to_s.to_f
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
    unless net_surface_area && net_surface_area.to_d > 0
      Rails.logger.warn 'No surface area. Cannot compute harvest yield'
      return nil
    end
    harvest_yield_unit_name = "#{size_unit_name}_per_#{surface_unit_name}".to_sym
    unless Nomen::Unit.find(harvest_yield_unit_name)
      raise "Harvest yield unit doesn't exist: #{harvest_yield_unit_name.inspect}"
    end
    total_quantity = 0.0.in(size_unit_name)
    # harvest_interventions = interventions.real.of_category(procedure_category).with_targets(inside_plants)
    harvest_interventions = Intervention.real.of_category(procedure_category).with_targets(inside_plants)
    if harvest_interventions.any?
      harvest_interventions.find_each do |harvest|
        harvest.outputs.each do |cast|
          actor = cast.product
          next unless actor && actor.variety
          variety = Nomen::Variety.find(actor.variety)
          if variety && variety <= harvest_variety
            quantity = cast.quantity_population.in(actor.variant.send(size_indicator_name).unit)
            total_quantity += quantity.convert(size_unit_name) if quantity
          end
        end
      end
    end
    harvest_yield = total_quantity.to_f / net_surface_area.to_d(surface_unit_name).to_f
    Measure.new(harvest_yield, harvest_yield_unit_name)
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

  # call method in production for instance
  def estimate_yield(options = {})
    options[:campaign] ||= campaign
    activity.estimate_yield_from_budget_of(options)
  end

  def current_cultivation
    # get the first object with variety 'plant', availables
    if cultivation = support.contents.where(type: Plant).of_variety(variant.variety).availables.reorder(:born_at).first
      return cultivation
    else
      return nil
    end
  end

  def unified_size_unit
    size_unit_name.blank? ? :unity : size_unit_name
  end

  # Compute quantity of a support as defined in production
  def current_size(options = {})
    options[:at] ||= self.started_on ? self.started_on.to_time : Time.zone.now
    value = support.get(size_indicator_name, options)
    value = value.in(size_unit_name) unless size_unit_name.blank?
    value
  end

  def duplicate!(updates = {})
    new_attributes = [
      :activity, :campaign, :cultivable_zone, :irrigated, :nitrate_fixing,
      :size_indicator_name, :size_unit_name, :size_value, :started_on,
      :support_nature, :support_shape, :usage
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
    list << cultivable_zone.name if cultivable_zone
    v = Nomen::Variety.find(cultivation_variety)
    list << v.human_name if v && !(activity.name.start_with?(v.human_name) || activity.name.end_with?(v.human_name))
    # list << support.name if !options[:support].is_a?(FalseClass) && support
    list << started_on.to_date.l(format: :month) if started_on
    list << :rank.t(number: rank_number)
    list = list.reverse! if 'i18n.dir'.t == 'rtl'
    list.join(' ')
  end

  def get(*args)
    unless support.present?
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
