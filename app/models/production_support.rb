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
# == Table: production_supports
#
#  created_at         :datetime         not null
#  creator_id         :integer
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  production_id      :integer          not null
#  production_usage   :string           not null
#  quantity           :decimal(19, 4)   not null
#  quantity_indicator :string           not null
#  quantity_unit      :string
#  storage_id         :integer          not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#

class ProductionSupport < Ekylibre::Record::Base
  refers_to :production_usage

  belongs_to :production, inverse_of: :supports
  belongs_to :storage, class_name: 'Product', inverse_of: :supports
  has_many :interventions
  has_many :manure_management_plan_zones, class_name: 'ManureManagementPlanZone', foreign_key: :support_id, inverse_of: :support
  has_one :activity, through: :production
  has_one :campaign, through: :production
  has_one :selected_manure_management_plan_zone, -> { selecteds }, class_name: 'ManureManagementPlanZone', foreign_key: :support_id, inverse_of: :support
  has_one :cultivation_variant, through: :production
  has_one :variant, through: :production

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, allow_nil: true
  validates_presence_of :production, :production_usage, :quantity, :quantity_indicator, :storage
  # ]VALIDATORS]
  validates_uniqueness_of :storage_id, scope: :production_id

  delegate :name, :net_surface_area, :shape_area, to: :storage, prefix: true
  delegate :support_variant_unit, :support_variant_indicator, to: :production
  delegate :name, :variant, to: :production, prefix: true
  delegate :name, :work_number, :shape, :shape_to_ewkt, :shape_svg, to: :storage
  delegate :name, to: :activity, prefix: true
  delegate :name, to: :campaign, prefix: true
  delegate :name, to: :variant,  prefix: true
  delegate :name, to: :cultivation_variant, prefix: true
  delegate :irrigated, :nitrate_fixing, :started_at, :stopped_at, :support_variant_indicator, :support_variant_unit, to: :production

  scope :of_campaign, lambda { |*campaigns|
    joins(:production).merge(Production.of_campaign(*campaigns))
  }

  scope :of_cultivation_variants, lambda { |*variants|
    joins(:production).merge(Production.of_cultivation_variants(*variants))
  }

  scope :of_cultivation_varieties, lambda { |*varieties|
    joins(:production).merge(Production.of_cultivation_varieties(*varieties))
  }

  scope :of_current_campaigns, -> { joins(:production).merge(Production.of_currents_campaigns) }
  scope :of_currents_campaigns, -> { of_current_campaigns }

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      fail ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
    end
    joins(:production).merge(Production.of_activities(activities))
  }

  scope :of_activity_families, lambda { |*families|
    joins(:activity).merge(Activity.of_families(families.flatten))
  }

  scope :of_productions, lambda { |*productions|
    productions.flatten!
    ids = productions.map do |production|
      # raise ArgumentError.new("Expected Production, got #{production.class.name}:#{production.inspect}") unless production.is_a?(Production)
      (production.is_a?(Production) ? production.id : production.to_i)
    end
    where(production_id: ids)
  }

  before_validation do
    self.production_usage = Nomen::ProductionUsage.first unless production_usage
    if self.production
      self.quantity_indicator = support_variant_indicator
      self.quantity_unit      = support_variant_unit
    end
    self.quantity ||= current_quantity if storage && quantity_indicator
  end

  validate do
    if self.production
      errors.add(:quantity_indicator, :invalid) unless quantity_indicator == support_variant_indicator
      if support_variant_unit
        errors.add(:quantity_unit, :invalid) unless quantity_unit == support_variant_unit
      end
    end
  end

  after_validation do
    if self.production
      self.started_at ||= self.production.started_at if self.production.started_at
      self.stopped_at ||= self.production.stopped_at if self.production.stopped_at
    end
  end

  def active?
    if activity.family.to_s == 'fallow_land'
      return false
    else
      return true
    end
  end

  def cost(role = :input)
    costs = interventions.collect do |intervention|
      intervention.cost(role)
    end
    costs.compact.sum
  end

  # Returns the spreaded quantity of one chemicals components (N, P, K) per area unit
  # Get all intervention of nature 'soil_enrichment' and sum all indicator unity spreaded
  #  - indicator could be (:potassium_concentration, :nitrogen_concentration, :phosphorus_concentration)
  #  - area_unit could be (:hectare, :square_meter)
  #  - from and to used to select intervention
  def soil_enrichment_indicator_content_per_area(indicator, from = nil, to = nil, area_unit = :hectare)
    balance = []
    procedure_nature = :soil_enrichment
    if from && to
      interventions = self.interventions.real.of_nature(procedure_nature).between(from, to)
    else
      interventions = self.interventions.real.of_nature(procedure_nature)
    end
    interventions.each do |intervention|
      intervention.casts.of_role("#{procedure_nature}-input").each do |input|
        # m = net_mass of the input at intervention time
        # n = indicator (in %) of the input at intervention time
        m = (input.actor ? input.actor.net_mass(input).to_d(:kilogram) : 0.0)
        # TODO: for method phosphorus_concentration(input)
        n = (input.actor ? input.actor.send(indicator).to_d(:unity) : 0.0)
        balance << m * n
      end
    end
    # if net_surface_area, make the division
    area = net_surface_area.to_d(area_unit)
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

  def tool_cost(surface_unit = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:tool) / (net_surface_area.to_d(surface_unit).to_s.to_f)
    end
    0.0
  end

  def input_cost(surface_unit = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:input) / (net_surface_area.to_d(surface_unit).to_s.to_f)
    end
    0.0
  end

  def time_cost(surface_unit = :hectare)
    if net_surface_area.to_s.to_f > 0.0
      return cost(:doer) / (net_surface_area.to_d(surface_unit).to_s.to_f)
    end
    0.0
  end

  # return the started_at attribute of the intervention of nature sowing if exist and if it's a vegetal production

  # when a plant is born in a production context ?
  # FIXME: Not generic
  def implanted_at
    # case wine or tree
    if implant_intervention = interventions.real.of_nature(:implanting).first
      return implant_intervention.started_at
    # case annual crop like cereals
    elsif implant_intervention = interventions.real.of_nature(:sowing).first
      return implant_intervention.started_at
    end
    nil
  end

  # return the started_at attribute of the intervention of nature harvesting if exist and if it's a vegetal production
  # FIXME: Not generic
  def harvested_at
    if harvest_intervention = interventions.real.of_nature(:harvest).first
      return harvest_intervention.started_at
    end
    nil
  end

  # Generic method to get harvest yield
  def harvest_yield(harvest_variety, options = {})
    quantity_indicator = options[:quantity_indicator] || :net_mass
    ind = Nomen::Indicator.find(quantity_indicator)
    fail "Invalid indicator: #{quantity_indicator}" unless ind
    quantity_unit = options[:quantity_unit] || ind.unit
    unless Nomen::Unit.find(quantity_unit)
      fail "Invalid indicator unit: #{quantity_unit.inspect}"
    end
    surface_unit = options[:surface_unit] || :hectare
    procedure_nature = options[:procedure_nature] || :harvest
    harvest_interventions = interventions.real.of_nature(procedure_nature)
    if harvest_interventions.any?
      quantities = []
      role = "#{procedure_nature}-output"
      harvest_interventions.find_each do |harvest|
        harvest.casts.of_role(role).each do |cast|
          actor = cast.actor
          if actor && actor.variety
            variety = Nomen::Variety.find(actor.variety)
            if variety && variety <= harvest_variety
              quantities << actor.get(quantity_indicator, cast).to_d(quantity_unit)
            end
          end
        end
      end
      if net_surface_area
        harvest_yield = quantities.compact.sum.to_f / net_surface_area.to_d(surface_unit).to_f
        harvest_yield_unit = "#{quantity_unit}_per_#{surface_unit}".to_sym
        if Nomen::Unit.find(harvest_yield_unit)
          return Measure.new(harvest_yield, harvest_yield_unit)
        else
          Rails.logger.warn "Cannot find unit: #{harvest_yield_unit}"
          return harvest_yield
        end
      end
    end
    nil
  end

  # Returns the yield of grain in mass per surface unit
  def grains_yield(mass_unit = :quintal, surface_unit = :hectare)
    harvest_yield(:grain, procedure_nature: :grains_harvest,
                          quantity_indicator: :net_mass,
                          quantity_unit: mass_unit,
                          surface_unit: surface_unit)
  end

  # Returns the yield of grape in volume per surface unit
  def vine_yield(volume_unit = :hectoliter, surface_unit = :hectare)
    harvest_yield(:grape, procedure_nature: :vine_harvest,
                          quantity_indicator: :net_volume,
                          quantity_unit: volume_unit,
                          surface_unit: surface_unit)
  end

  # call method in production for instance
  def estimate_yield(options = {})
    production.estimate_yield(options)
  end

  def current_cultivation
    # get the first object with variety 'plant', availables
    if cultivation = storage.contents.where(type: Plant).of_variety(variant.variety).availables.reorder(:born_at).first
      return cultivation
    else
      return nil
    end
  end

  def unified_quantity_unit
    quantity_unit.blank? ? :unity : quantity_unit
  end

  # Compute quantity of a support as defined in production
  def current_quantity(options = {})
    value = get(quantity_indicator, options)
    value = value.in(quantity_unit) unless quantity_unit.blank?
    value.to_d
  end

  def net_surface_area
    area = 0.0.in_square_meter
    area = self.quantity.in(quantity_unit) if quantity_indicator == 'net_surface_area'
    area
  end

  def work_name
    "#{storage.work_name} - #{net_surface_area}"
  end

  def get(*args)
    unless storage.present?
      fail StandardError, "No storage defined. Got: #{storage.inspect}"
    end
    storage.get(*args)
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicator.all.include?(method_name.to_s)
      return get(method_name, *args)
    end
    super
  end
end
