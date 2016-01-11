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
#  created_at          :datetime         not null
#  creator_id          :integer
#  cultivable_zone_id  :integer
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
  enumerize :support_nature, in: [:cultivation, :fallow_land, :buffer, :border, :none], default: :cultivation
  refers_to :usage, class_name: 'ProductionUsage'
  refers_to :size_indicator, class_name: 'Indicator'
  refers_to :size_unit, class_name: 'Unit'
  belongs_to :activity, inverse_of: :productions
  belongs_to :cultivable_zone
  belongs_to :support, class_name: 'Product' # , inverse_of: :supports
  has_many :budgets, through: :activity
  has_many :manure_management_plan_zones, class_name: 'ManureManagementPlanZone',
                                          inverse_of: :activity_production
  has_one :selected_manure_management_plan_zone, -> { selecteds },
          class_name: 'ManureManagementPlanZone', inverse_of: :activity_production

  has_geometry :support_shape
  composed_of :size, class_name: 'Measure', mapping: [%w(size_value to_d), %w(size_unit_name unit)]

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_date :started_on, :stopped_on, allow_blank: true, on_or_after: Date.civil(1, 1, 1)
  validates_numericality_of :rank_number, allow_nil: true, only_integer: true
  validates_numericality_of :size_value, allow_nil: true
  validates_inclusion_of :irrigated, :nitrate_fixing, in: [true, false]
  validates_presence_of :activity, :rank_number, :size_indicator_name, :size_value, :support, :usage
  # ]VALIDATORS]
  validates_uniqueness_of :rank_number, scope: :activity_id
  validates_presence_of :started_on
  validates_presence_of :cultivable_zone, :support_nature, if: :vegetal_crops?

  delegate :name, :net_surface_area, :shape_area, to: :support, prefix: true
  delegate :name, :work_number, :shape, :shape_to_ewkt, :shape_svg, to: :support
  delegate :name, :size_indicator_name, :size_unit_name, to: :activity, prefix: true
  delegate :vegetal_crops?, :with_cultivation, :cultivation_variety, :with_supports,
           :support_variety, :color, to: :activity

  scope :of_campaign, lambda { |campaigns|
    campaigns = [campaigns] unless campaigns.respond_to? :map
    args = []
    query = campaigns.map do |campaign|
      args << campaign.started_on
      args << campaign.stopped_on
      '(started_on, stopped_on) OVERLAPS (?, ?)'
    end
    where(query.join(' OR '), *args)
  }

  scope :of_cultivation_variety, lambda { |variety|
    where(activity: Activity.of_cultivation_variety(variety))
  }
  scope :of_current_campaigns, -> { where(activity: Activity.of_current_campaigns) }

  scope :of_activity, ->(activity) { where(activity: activity) }
  scope :of_activities, lambda { |*activities|
    where(activity_id: activities.flatten.map(&:id))
  }
  scope :of_activity_families, lambda { |*families|
    where(activity: Activity.of_families(*families))
  }
  scope :current, -> { where(':now BETWEEN COALESCE(started_on, :now) AND COALESCE(stopped_on, :now)', now: Time.zone.now) }
  scope :overlaps_shape, lambda { |shape|
    where('ST_Overlaps(support_shape, ST_GeomFromEWKT(?))', ::Charta.new_geometry(shape).to_ewkt)
  }

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
    self.rank_number = (self.activity.productions.maximum(:rank_number) ? self.activity.productions.maximum(:rank_number) : 0) + 1
  end

  before_validation do
    self.usage = Nomen::ProductionUsage.first unless usage
    if self.activity
      self.size_indicator_name ||= activity_size_indicator_name if activity_size_indicator_name
      self.size_unit_name      = activity_size_unit_name
      self.rank_number ||= (self.activity.productions.maximum(:rank_number) ? self.activity.productions.maximum(:rank_number) : 0) + 1
    end
    if !support && cultivable_zone && support_shape && self.vegetal_crops?
      land_parcels = LandParcel.overlaps_shape(::Charta.new_geometry(support_shape)).order(:id)
      if land_parcels.any?
        land_parcel = land_parcels.first
      else
        list = [cultivable_zone.name, :rank.t(number: rank_number)]
        list = list.reverse! if 'i18n.dir'.t == 'rtl'
        land_parcel = LandParcel.new(name: list.join(' '), initial_shape: support_shape, initial_born_at: started_on, variant: ProductNatureVariant.import_from_nomenclature(:land_parcel))
        land_parcel.save!
        land_parcel.read!(:shape, support_shape, at: started_on)
      end
      self.support = land_parcel
    end
    self.size = current_size if support && size_indicator_name && size_unit_name
  end

  before_validation(on: :create) do
    self.state ||= :opened
  end

  after_commit do
    if self.activity.productions.where(rank_number: rank_number).count > 1
      update_column(:rank_number, self.activity.productions.maximum(:rank_number) + 1)
    end
    Ekylibre::Hook.publish(:activity_production_change, activity_production_id: id)
  end

  def active?
    if activity.family.to_s == 'fallow_land'
      return false
    else
      return true
    end
  end

  # Returns interventions of current production
  def interventions
    Intervention.of_activity_production(self)
  end

  def campaigns
    Campaign.of_activity_production(self)
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
    if from && to
      interventions = self.interventions.real.of_category(procedure_category).between(from, to)
    else
      interventions = self.interventions.real.of_category(procedure_category)
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
      return cost(:tool) / (net_surface_area.to_d(surface_unit_name).to_s.to_f)
    end
    0.0
  end

  def input_cost(surface_unit_name = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:input) / (net_surface_area.to_d(surface_unit_name).to_s.to_f)
    end
    0.0
  end

  def time_cost(surface_unit_name = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:doer) / (net_surface_area.to_d(surface_unit_name).to_s.to_f)
    end
    0.0
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
    fail "Invalid indicator: #{size_indicator_name}" unless ind
    size_unit_name = options[:size_unit_name] || ind.unit
    unless Nomen::Unit.find(size_unit_name)
      fail "Invalid indicator unit: #{size_unit_name.inspect}"
    end
    surface_unit_name = options[:surface_unit_name] || :hectare
    procedure_category = options[:procedure_category] || :harvesting
    unless net_surface_area && net_surface_area.to_d > 0
      Rails.logger.warn 'No surface area. Cannot compute harvest yield'
      return nil
    end
    harvest_yield_unit_name = "#{size_unit_name}_per_#{surface_unit_name}".to_sym
    unless Nomen::Unit.find(harvest_yield_unit_name)
      fail "Harvest yield unit doesn't exist: #{harvest_yield_unit_name.inspect}"
    end
    total_quantity = 0.0.in(size_unit_name)
    harvest_interventions = interventions.real.of_category(procedure_category)
    if harvest_interventions.any?
      harvest_interventions.find_each do |harvest|
        harvest.outputs.each do |cast|
          actor = cast.actor
          next unless actor && actor.variety
          variety = Nomen::Variety.find(actor.variety)
          if variety && variety <= harvest_variety
            total_quantity += actor.get(size_indicator_name, cast)
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
    fail 'Not possible anymore'
    production.estimate_yield(options)
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
    value = get(size_indicator_name, options)
    value = value.in(size_unit_name) unless size_unit_name.blank?
    value
  end

  def duplicate!(updates = {})
    new_attributes = [
      :activity, :cultivable_zone, :irrigated, :nitrate_fixing,
      :size_indicator_name, :size_unit_name, :size_value, :started_on, :support,
      :support_nature, :support_shape, :usage].each_with_object({}) do |attr, h|
      h[attr] = send(attr)
      h
    end.merge(updates)
    self.class.create!(new_attributes)
  end

  ## AREA METHODS ##

  def to_geom
    ::Charta.new_geometry(support_shape)
  end

  def net_surface_area(unit_name = :hectare)
    area = 0.0.in(unit_name)
    if size_indicator_name == 'net_surface_area' && size_value != 0.0
      area = size
    elsif support_shape
      area = to_geom.area.in(unit_name).round(3)
    end
    area
  end

  ## LABEL METHODS ##

  def work_name
    "#{support.work_name} - #{net_surface_area}"
  end

  # Returns unique i18nized name for given production
  def name(options = {})
    list = []
    list << activity.name unless options[:activity].is_a?(FalseClass)
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
      fail StandardError, "No support defined. Got: #{support.inspect}"
    end
    support.get(*args)
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicator.include?(method_name.to_s)
      return get(method_name, *args)
    end
    super
  end
end
