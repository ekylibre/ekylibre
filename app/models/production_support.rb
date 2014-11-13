# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  created_at       :datetime         not null
#  creator_id       :integer
#  exclusive        :boolean          not null
#  id               :integer          not null, primary key
#  irrigated        :boolean          not null
#  lock_version     :integer          default(0), not null
#  nature           :string(255)      not null
#  production_id    :integer          not null
#  production_usage :string(255)      not null
#  started_at       :datetime
#  stopped_at       :datetime
#  storage_id       :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class ProductionSupport < Ekylibre::Record::Base
  enumerize :nature, in: [:main, :secondary, :nitrate_trap], default: :main
  enumerize :production_usage, in: Nomen::ProductionUsages.all, default: Nomen::ProductionUsages.default

  belongs_to :production, inverse_of: :supports
  belongs_to :storage, class_name: "Product", inverse_of: :supports
  has_many :interventions
  has_many :manure_management_plan_zones, class_name: "ManureManagementPlanZone", foreign_key: :support_id, inverse_of: :support
  has_many :markers, class_name: "ProductionSupportMarker", foreign_key: :support_id, inverse_of: :support, dependent: :destroy
  has_one :activity, through: :production
  has_one :campaign, through: :production
  has_one :selected_manure_management_plan_zone, -> { selected }, class_name: "ManureManagementPlanZone", foreign_key: :support_id, inverse_of: :support
  has_one :variant, through: :production

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_length_of :nature, :production_usage, allow_nil: true, maximum: 255
  validates_inclusion_of :exclusive, :irrigated, in: [true, false]
  validates_presence_of :nature, :production, :production_usage, :storage
  #]VALIDATORS]
  validates_uniqueness_of :storage_id, scope: :production_id

  delegate :net_surface_area, :shape_area, to: :storage, prefix: true
  delegate :name, :variant, to: :production, prefix: true
  delegate :name, :work_number, :shape, :shape_to_ewkt, :shape_svg, to: :storage
  delegate :name, to: :activity, prefix: true
  delegate :name, to: :campaign, prefix: true
  delegate :name, to: :variant,  prefix: true

  accepts_nested_attributes_for :markers, reject_if: :all_blank, allow_destroy: true

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    joins(:production).merge(Production.of_campaign(campaigns))
  }

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      raise ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
    end
    joins(:production).merge(Production.of_activities(activities))
  }

  scope :of_activity_families, lambda { |*families|
    joins(:activity).merge(Activity.of_families(families.flatten))
  }

  scope :of_productions, lambda { |*productions|
    productions.flatten!
    for production in productions
      raise ArgumentError.new("Expected Production, got #{production.class.name}:#{production.inspect}") unless production.is_a?(Production)
    end
    where(production_id: productions.map(&:id))
  }

  # Measure a product for a given indicator
  def read!(indicator, value, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    if value.nil?
      raise ArgumentError, "Value must be given"
    end
    options[:indicator_name] = indicator.name
    options[:aim] ||= :perfect
    options.delete(:derivative) if options[:derivative].blank?
    options[:subject] ||= (options[:derivative] ? :derivative : :support)
    unless marker = self.markers.find_by(options)
      marker = self.markers.build(options)
    end
    marker.value = value
    marker.save!
    return marker
  end

  def active?
    if self.activity.fallow_land?
      return false
    else
      return true
    end
  end

  def cost(role=:input)
    cost = []
    for intervention in self.interventions
      cost << intervention.cost(role)
    end
    return cost.compact.sum
  end

  # @TODO for nitrogen balance but will be refactorize for any chemical components
  def nitrogen_balance
    #
    # get all intervention of nature 'soil_enrichment' and sum all nitrogen unity spreaded
    # m = net_mass of the input at intervention time
    # n = nitrogen concentration (in %) of the input at intervention time
    #
    # B = O - I
    balance = 0.0
    nitrogen_mass = []
    nitrogen_unity_per_hectare = nil
    if self.selected_manure_management_plan_zone
      # get the output O aka nitrogen_input from opened_at (in kg N / Ha )
      o = self.selected_manure_management_plan_zone.nitrogen_input.to_d
      opened_at = self.selected_manure_management_plan_zone.opened_at
      # get the nitrogen input I from opened_at to now (in kg N / Ha )
      for intervention in self.interventions.real.where(state: 'done').of_nature(:soil_enrichment).between(opened_at, Time.now)
        for input in intervention.casts.of_role('soil_enrichment-input')
          m = (input.actor ? input.actor.net_mass(input).to_d(:kilogram) : 0.0)
          # TODO for method phosphorus_concentration(input)
          n = (input.actor ? input.actor.nitrogen_concentration.to_d(:unity) : 0.0)
          nitrogen_mass <<  m * n
        end
      end
      # if net_surface_area, make the division
      if surface_area = self.storage_net_surface_area(self.started_at)
        i = (nitrogen_mass.compact.sum / surface_area.to_d(:hectare)).to_d
      end
      if i and o
        balance = o - i
      end
    end
    return balance
  end

  def potassium_balance
    balance = []
    # get all intervention of nature 'soil_enrichment' and sum all nitrogen unity spreaded
    # m = net_mass of the input at intervention time
    # n = nitrogen concentration (in %) of the input at intervention time
    for intervention in self.interventions.real.of_nature(:soil_enrichment)
      for input in intervention.casts.of_role('soil_enrichment-input')
        m = (input.actor ? input.actor.net_mass(input).to_d(:kilogram) : 0.0)
        # TODO for method phosphorus_concentration(input)
        n = (input.actor ? input.actor.potassium_concentration.to_d(:unity) : 0.0)
        balance <<  m * n
      end
    end
    # if net_surface_area, make the division
    if surface_area = self.storage_net_surface_area(self.started_at)
      potassium_unity_per_hectare = (balance.compact.sum / surface_area.to_d(:hectare))
    end
    return potassium_unity_per_hectare
  end

  def phosphorus_balance
    balance = []
    # get all intervention of nature 'soil_enrichment' and sum all nitrogen unity spreaded
    # m = net_mass of the input at intervention time
    # n = nitrogen concentration (in %) of the input at intervention time
    for intervention in self.interventions.real.of_nature(:soil_enrichment)
      # puts "I#{intervention.id}".red
      for input in intervention.casts.of_role('soil_enrichment-input')
        # puts "C#{input.id}".yellow
        m = (input.actor ? input.actor.net_mass(input).to_f(:kilogram) : 0.0)
        # TODO for method phosphorus_concentration(input)
        n = (input.actor ? input.actor.phosphorus_concentration.to_f(:unity) : 0.0)
        balance <<  m * n
      end
    end
    # puts balance.inspect.green
    # if net_surface_area, make the division
    if surface_area = self.storage_net_surface_area(self.started_at)
      phosphorus_unity_per_hectare = (balance.compact.sum / surface_area.to_f(:hectare))
    end
    # puts phosphorus_unity_per_hectare.inspect.red
    return phosphorus_unity_per_hectare
  end


  def provisional_nitrogen_input
    balance = []
    markers = self.markers.where(aim: 'perfect', indicator_name: 'nitrogen_input_per_area')
    if markers.count > 0
      for marker in markers
        balance << marker.measure_value_value
      end
      return balance.compact.sum
    else
      return 0
    end
  end

  def tool_cost(surface_unit = :hectare)
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      self.cost(:tool)/(self.storage_net_surface_area(self.started_at).to_d(surface_unit).to_s.to_f)
    end
  end

  def input_cost(surface_unit = :hectare)
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      self.cost(:input)/(self.storage_net_surface_area(self.started_at).to_d(surface_unit).to_s.to_f)
    end
  end

  def time_cost(surface_unit = :hectare)
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      self.cost(:doer)/(self.storage_net_surface_area(self.started_at).to_d(surface_unit).to_s.to_f)
    end
  end

  # return the started_at attribute of the intervention of nature sowing if exist and if it's a vegetal production

  # when a plant is born in a production context ?
  def implanted_at
    # case wine or tree
    if implant_intervention = self.interventions.real.of_nature(:implanting).first
      return implant_intervention.started_at
    # case annual crop like cereals
    elsif implant_intervention = self.interventions.real.of_nature(:sowing).first
      return implant_intervention.started_at
    end
    return nil
  end

  # return the started_at attribute of the intervention of nature harvesting if exist and if it's a vegetal production
  def harvested_at
    if harvest_intervention = self.interventions.real.of_nature(:harvest).first
      return harvest_intervention.started_at
    end
    return nil
  end

  def grains_yield(mass_unit = :quintal, surface_unit = :hectare)
    if self.interventions.real.of_nature(:harvest).count > 0
      total_yield = []
      for harvest in self.interventions.real.of_nature(:harvest)
        for input in harvest.casts.of_role('harvest-output')
          q = (input.actor ? input.actor.net_mass(input).to_d(mass_unit) : 0.0) if input.actor.variety == 'grain'
          total_yield << q
        end
      end
      if self.storage.net_surface_area
        return ((total_yield.compact.sum) / (self.storage.net_surface_area.to_d(surface_unit)))
      end
    end
    return nil
  end

  def vine_yield(volume_unit = :hectoliter, surface_unit = :hectare)
    if self.interventions.real.of_nature(:harvest).count > 0
      total_yield = []
      for harvest in self.interventions.real.of_nature(:harvest)
        for input in harvest.casts.of_role('harvest-output')
          q = (input.actor ? input.actor.net_volume(input).to_d(volume_unit) : 0.0) if input.actor.variety == 'grape'
          total_yield << q
        end
      end
      if self.storage.net_surface_area
        return ((total_yield.compact.sum) / (self.storage.net_surface_area.to_d(surface_unit)))
      end
    end
    return nil
  end

  def cultivation
    # FIXME How to get cultivation ?
    nil
  end

  def get(indicator, *args)
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    options = args.extract_options!
    aim = args.shift || options[:aim] || :perfect
    markers = self.markers.where(indicator_name: indicator.name.to_s, aim: aim)
    if markers.any?
      return markers.first.value
    end
    return nil
  end

  # Returns value of an indicator if its name correspond to
  def method_missing(method_name, *args)
    if Nomen::Indicators.all.include?(method_name.to_s)
      return get(method_name, *args)
    end
    return super
  end

end


