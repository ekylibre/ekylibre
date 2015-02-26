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
# == Table: productions
#
#  activity_id          :integer          not null
#  campaign_id          :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string           not null
#  position             :integer
#  producing_variant_id :integer
#  started_at           :datetime
#  state                :string           not null
#  stopped_at           :datetime
#  support_variant_id   :integer
#  updated_at           :datetime         not null
#  updater_id           :integer
#  working_indicator    :string
#  working_unit         :string
#
class Production < Ekylibre::Record::Base
  enumerize :state, in: [:draft, :validated], default: :draft
  enumerize :working_unit, in: Nomen::Units.all
  enumerize :working_indicator, in: Nomen::Indicators.where(datatype: :measure).map(&:name) + [:population, :working_duration]
  belongs_to :activity
  belongs_to :campaign
  belongs_to :producing_variant, class_name: "ProductNatureVariant"
  belongs_to :support_variant, class_name: "ProductNatureVariant"
  belongs_to :variant, class_name: "ProductNatureVariant", foreign_key: :producing_variant_id
  has_many :analytic_distributions
  has_many :activity_distributions, through: :activity, source: :distributions
  has_many :budgets, class_name: "ProductionBudget"
  has_many :expenses, -> { where(direction: :expense) }, class_name: 'ProductionBudget'
  has_many :revenues, -> { where(direction: :revenue) }, class_name: 'ProductionBudget'
  has_many :distributions, class_name: "ProductionDistribution", dependent: :destroy, inverse_of: :production
  has_many :supports, class_name: "ProductionSupport", inverse_of: :production, dependent: :destroy
  # has_many :markers, through: :supports, class_name: "ProductionSupportMarker"
  has_many :interventions, inverse_of: :production
  has_many :storages, through: :supports
  has_many :casts, through: :interventions, class_name: "InterventionCast"
  # has_many :selected_manure_management_plan_zones, class_name: "ManureManagementPlanZone", through: :supports
  # has_many :land_parcel_groups, :through => :supports, class_name: "Product" #, :conditions => {:variety => "land_parcel_group"}

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :activity, :campaign, :name, :state
  #]VALIDATORS]
  # validates_presence_of :product_nature, if: :activity_main?
  validates_associated :budgets

  alias_attribute :label, :name
  alias_attribute :product_variant, :producing_variant

  delegate :name, :variety, to: :producing_variant, prefix: true
  delegate :name, :variety, to: :variant, prefix: true
  delegate :main?, :auxiliary?, :standalone?, to: :activity

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    where(campaign_id: campaigns.map(&:id))
  }

  scope :main_of_campaign, lambda { |campaign| where(activity: Activity.main, campaign_id: (campaign.is_a?(Campaign) ? campaign.id : campaign.to_i)) }

  scope :of_currents_campaigns, -> { joins(:campaign).merge(Campaign.currents)}

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      raise ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
    end
    where(activity_id: activities.map(&:id))
  }

  scope :actives, -> {
    at = Time.now
    where(arel_table[:started_at].eq(nil).or(arel_table[:started_at].lteq(at)).and(arel_table[:stopped_at].eq(nil).or(arel_table[:stopped_at].gt(at))))
  }

  accepts_nested_attributes_for :supports, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :budgets, :expenses, :revenues, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :distributions, reject_if: :all_blank, allow_destroy: true


  state_machine :state, :initial => :draft do
    state :draft
    state :aborted
    state :validated
    state :started
    state :closed

    event :correct do
      transition :validated => :draft
    end

    event :abort do
      transition :draft => :aborted
    end

    event :confirm do
      transition :draft => :validated
    end

    event :start do
      transition :validated => :started
    end

    event :close do
      transition :started => :closed
    end

  end

  protect(on: :destroy) do
    self.interventions.any? or self.distributions.any?
  end

  before_validation(on: :create) do
    self.state ||= :draft
  end

  before_validation do
    if self.activity and self.campaign and self.producing_variant
      self.name = tc(:name, state: self.state_label, activity: self.activity.name, variant: self.producing_variant.name, campaign: self.campaign.name)
    elsif self.activity and self.campaign
      self.name = tc(:name_without_variant, state: self.state_label, activity: self.activity.name, campaign: self.campaign.name)
    end
  end

  def activity_main?
    self.activity and self.activity_main?
  end

  def has_active_product?
    self.producing_variant.nature.active?
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # Prints human name of current production
  def state_label
    self.class.state_label(self.state)
  end

  def shape_area
    if self.supports.any?
      return self.supports.map(&:storage_shape_area).compact.sum
    end
    return 0.0.in_square_meter
  end

  def net_surface_area
    if self.supports.any?
      return self.supports.map(&:storage_net_surface_area).compact.sum
    end
    return 0.0.in_square_meter
  end

  # Returns the count of supports
  def supports_count
    self.supports.count
  end

  def area
    # raise "NO AREA"
    ActiveSupport::Deprecation.warn("#{self.class.name}#area is deprecated. Please use #{self.class.name}#net_surface_area instead.")
    return net_surface_area
  end

  def duration
    if self.interventions.any?
      return self.interventions.map(&:duration).compact.sum
    end
    return 0
  end

  def cost(role = :input)
    if interventions = self.interventions
      cost_array = []
      for intervention in interventions
        cost_array << intervention.cost(role)
      end
      return cost_array.compact.sum
    else
      return 0
    end
  end

  def earn
    if interventions = self.interventions
      earn_array = []
      for intervention in interventions
        earn_array << intervention.earn
      end
      return earn_array.compact.sum
    else
      return 0
    end
  end

  def indirect_budget_amount
    global_value = 0
    for indirect_distribution in ProductionDistribution.where(main_production_id: self.id)
      distribution_value = 0
      distribution_percentage = indirect_distribution.affectation_percentage
      production = indirect_distribution.production
      #puts "Percentage : #{distribution_percentage.inspect}".red
      # get indirect expenses and revenues on current production
      # distribution_value - expenses
      indirect_expenses_value = production.expenses.sum(:global_amount).to_d
      distribution_value -= indirect_expenses_value if indirect_expenses_value > 0.0
      #puts "Indirect expenses : #{indirect_expenses_value.inspect}".blue
      #puts "Distribution value : #{distribution_value.inspect}".yellow
      # distribution_value + revenues
      indirect_revenues_value = production.revenues.sum(:global_amount).to_d
      distribution_value += indirect_revenues_value.to_d if indirect_revenues_value > 0.0
      #puts "Indirect revenues : #{indirect_revenues_value.inspect}".blue
      #puts "Distribution value : #{distribution_value.inspect}".yellow
      # distribution_value * % of distribution
      global_value += (distribution_value.to_d * (distribution_percentage.to_d / 100))
      #puts "Global value : #{global_value.inspect}".yellow
    end
    return global_value
  end

  def direct_budget_amount
    global_value = 0

      direct_expenses_value = self.expenses.sum(:global_amount).to_d
      distribution_value -= direct_expenses_value if direct_expenses_value > 0.0

      direct_revenues_value = self.revenues.sum(:global_amount).to_d
      distribution_value += direct_revenues_value.to_d if direct_revenues_value > 0.0

      global_value += distribution_value.to_d
    return global_value
  end

  def global_cost
    self.direct_budget_amount + self.indirect_budget_amount
  end

  def quandl_dataset
    if Nomen::Varieties[self.producing_variant_variety.to_sym] <= :triticum_aestivum
      return 'CHRIS/LIFFE_EBM4'
    elsif Nomen::Varieties[self.producing_variant_variety.to_sym] <= :brassica_napus
      return 'CHRIS/LIFFE_ECO4'
    elsif Nomen::Varieties[self.producing_variant_variety.to_sym] <= :hordeum_vernum
      return 'ODA/PBARL_USD'
    end
  end

  def active?
    if self.activity.fallow_land?
      return false
    else
      return true
    end
  end

end
