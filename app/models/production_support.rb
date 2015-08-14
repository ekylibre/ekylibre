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

  scope :of_currents_campaigns, -> { joins(:production).merge(Production.of_currents_campaigns) }

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
    unless self.production_usage
      self.production_usage = Nomen::ProductionUsage.first
    end
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
    if activity.family.to_s == "fallow_land"
      return false
    else
      return true
    end
  end

  def cost(role = :input)
    cost = []
    for intervention in interventions
      cost << intervention.cost(role)
    end
    cost.compact.sum
  end

  # return the spreaded quantity of one chemicals components (N, P, K) per area unit
  def soil_enrichment_indicator_content_per_area(indicator, from = nil, to = nil, area_unit = :hectare)
    balance = []
    # indicator could be (:potassium_concentration, :nitrogen_concentration, :phosphorus_concentration)
    # area_unit could be (:hectare, :square_meter)
    # from and to used to select intervention
    # get all intervention of nature 'soil_enrichment' and sum all indicator unity spreaded
    # m = net_mass of the input at intervention time
    # n = indicator (in %) of the input at intervention time
    if from && to
      interventions = self.interventions.real.of_nature(:soil_enrichment).between(from, to)
    else
      interventions = self.interventions.real.of_nature(:soil_enrichment)
    end
    for intervention in interventions
      for input in intervention.casts.of_role('soil_enrichment-input')
        m = (input.actor ? input.actor.net_mass(input).to_d(:kilogram) : 0.0)
        # TODO: for method phosphorus_concentration(input)
        n = (input.actor ? input.actor.send(indicator).to_d(:unity) : 0.0)
        balance << m * n
      end
    end
    # if net_surface_area, make the division
    if surface_area = storage_net_surface_area(self.started_at)
      indicator_unity_per_hectare = (balance.compact.sum / surface_area.to_d(area_unit))
    end
    indicator_unity_per_hectare
  end

  # @TODO for nitrogen balance but will be refactorize for any chemical components
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
      i = soil_enrichment_indicator_content_per_area(:nitrogen_concentration, opened_at, Time.now)
      balance = o - i if i && o
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
    if storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      return cost(:tool) / (storage_net_surface_area(self.started_at).to_d(surface_unit).to_s.to_f)
    end
    0.0
  end

  def input_cost(surface_unit = :hectare)
    if storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      return cost(:input) / (storage_net_surface_area(self.started_at).to_d(surface_unit).to_s.to_f)
    end
    0.0
  end

  def time_cost(surface_unit = :hectare)
    if storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      return cost(:doer) / (storage_net_surface_area(self.started_at).to_d(surface_unit).to_s.to_f)
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

  # FIXME: Not generic
  def grains_yield(mass_unit = :quintal, surface_unit = :hectare)
    if interventions.real.of_nature(:grains_harvest).count > 0
      total_yield = []
      for harvest in interventions.real.of_nature(:grains_harvest)
        for input in harvest.casts.of_role('harvest-output')
          q = 0.0
          q = input.actor.net_mass(input).to_d(mass_unit) if input.actor && input.actor.variety == 'grain'
          total_yield << q
        end
      end
      if storage.net_surface_area
        grain_yield = ((total_yield.compact.sum).to_f / (storage.net_surface_area.to_d(surface_unit)).to_f)
        return grain_yield
      end
    end
    nil
  end

  # FIXME: Not generic
  def vine_yield(volume_unit = :hectoliter, surface_unit = :hectare)
    if interventions.real.of_nature(:harvest).count > 0
      total_yield = []
      for harvest in interventions.real.of_nature(:harvest)
        for input in harvest.casts.of_role('harvest-output')
          q = (input.actor ? input.actor.net_volume(input).to_d(volume_unit) : 0.0) if input.actor.variety == 'grape'
          total_yield << q
        end
      end
      if storage.net_surface_area
        return ((total_yield.compact.sum) / (storage.net_surface_area.to_d(surface_unit)))
      end
    end
    nil
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

  def get(*args)
    unless storage.present?
      fail StandardError, "No storage defined. Got: #{storage.inspect}"
    end
    storage.get(*args)
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicators.all.include?(method_name.to_s)
      return get(method_name, *args)
    end
    super
  end
end
