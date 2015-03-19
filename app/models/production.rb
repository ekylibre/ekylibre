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
#  activity_id               :integer          not null
#  campaign_id               :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  cultivation_variant_id    :integer
#  id                        :integer          not null, primary key
#  irrigated                 :boolean          default(FALSE), not null
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  nitrate_fixing            :boolean          default(FALSE), not null
#  position                  :integer
#  started_at                :datetime
#  state                     :string           not null
#  stopped_at                :datetime
#  support_variant_id        :integer
#  support_variant_indicator :string
#  support_variant_unit      :string
#  updated_at                :datetime         not null
#  updater_id                :integer
#
class Production < Ekylibre::Record::Base
  # enumerize :support_variant_unit, in: Nomen::Units.all
  # enumerize :support_variant_indicator, in: Nomen::Indicators.where(datatype: :measure).map(&:name) + [:population, :working_duration]
  belongs_to :activity
  belongs_to :campaign
  belongs_to :cultivation_variant, class_name: "ProductNatureVariant"
  belongs_to :support_variant, class_name: "ProductNatureVariant"
  belongs_to :variant, class_name: "ProductNatureVariant", foreign_key: :cultivation_variant_id
  has_many :activity_distributions, through: :activity, source: :distributions
  has_many :budgets, class_name: "ProductionBudget"
  has_many :expenses, -> { where(direction: :expense).includes(:variant) }, class_name: 'ProductionBudget', inverse_of: :production
  has_many :revenues, -> { where(direction: :revenue).includes(:variant) }, class_name: 'ProductionBudget', inverse_of: :production
  has_many :distributions, class_name: "ProductionDistribution", dependent: :destroy, inverse_of: :production
  has_many :supports, class_name: "ProductionSupport", inverse_of: :production, dependent: :destroy
  has_many :interventions, inverse_of: :production
  has_many :storages, through: :supports
  has_many :casts, through: :interventions, class_name: "InterventionCast"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_inclusion_of :irrigated, :nitrate_fixing, in: [true, false]
  validates_presence_of :activity, :campaign, :name, :state
  #]VALIDATORS]
  validates_uniqueness_of :name, scope: :campaign_id
  validates_associated :expenses, :revenues

  alias_attribute :label, :name
  alias_attribute :product_variant, :cultivation_variant

  delegate :name, to: :activity, prefix: true
  delegate :name, :variety, to: :cultivation_variant, prefix: true
  delegate :name, :variety, to: :variant, prefix: true
  delegate :main?, :auxiliary?, :standalone?, :with_supports, :with_cultivation, :support_variety, :cultivation_variety, to: :activity

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
  accepts_nested_attributes_for :expenses, :revenues, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :distributions, reject_if: :all_blank, allow_destroy: true


  state_machine :state, :initial => :opened do
    state :opened
    state :aborted
    state :closed

    event :abort do
      transition :opened => :aborted
    end

    event :close do
      transition :opened => :closed
    end

    event :reopen do
      transition :closed => :opened
      transition :aborted => :opened
    end
  end

  protect(on: :update) do
    self.closed?
  end

  protect(on: :destroy) do
    self.interventions.any? or self.distributions.any?
  end

  before_validation(on: :create) do
    self.state ||= :opened
    if self.activity
      self.name ||= self.activity_name
      if self.support_variant
        unless self.support_variant_indicator
          if quantifier = self.support_variant.quantifiers.last
            pair = quantifier.split('/')
            self.support_variant_indicator = pair.first
            self.support_variant_unit = pair.second
          end
        end
      end
    end
  end

  validate do
    if self.activity
      if self.with_cultivation
        errors.add(:cultivation_variant_id, :blank) unless self.cultivation_variant
      end
      if self.with_supports
        if self.support_variant
          if indicator = Nomen::Indicators[self.support_variant_indicator]
            if indicator.datatype == :measure
              if unit = Nomen::Units[self.support_variant_unit]
                if unit.dimension.to_s != Nomen::Units[indicator.unit].dimension.to_s
                  errors.add(:support_variant_unit, :invalid)
                end
              else
                errors.add(:support_variant_unit, :blank)
              end
            end
          else
            errors.add(:support_variant_indicator, :blank)
          end
        else
          errors.add(:support_variant_id, :blank)
        end
      end
    end
  end

  def has_active_product?
    self.cultivation_variant.nature.active?
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # return estimate_yield for output varieties and quantity_unit / support_unit
  # return a Measure
  # example : Wheat ( quantity_unit = :quintal, support_unit = :hectare, varieties = [:grain])
  # will return the estimate_yield : 65.00 quintal_per_hectare
  def estimate_yield(quantity_unity = :quintal, support_unity = :hectare, varieties = :grain, options)


    #TODO refactorize to convert quantity_unity and support_unity into an existing unit like :quintal_per_hectare
    if quantity_unity == :quintal and support_unity == :hectare
      output_unit = :quintal_per_hectare
      output_item_unit = :quintal_per_hectare
    elsif quantity_unity == :ton and support_unity == :hectare
      output_unit = :ton_per_hectare
      output_item_unit = :ton_per_hectare
    end

    o = Measure.new(0, output_unit)

    if self.revenues
      product_budget_items = self.revenues.where(variant_id: ProductNatureVariant.of_variety(varieties).map(&:id))
      for item in product_budget_items
        # build divider
        if item.computation_method == :per_working_unit
          s = Measure.new(1, self.support_variant_unit)
        elsif item.computation_method == :per_production_support
          quantity = self.supports.sum(:quantity)
          s = Measure.new(quantity, self.support_variant_unit)
        end
        # build item yield
        m = Measure.new(item.quantity, item.variant_unit)
        output = (m.to_d(quantity_unity) / s.to_d(support_unity))
        output_measure = Measure.new(output, output_item_unit) if output
        o += output_measure if output_measure
      end
    end
    return o
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

  # Sums all quantity of supports
  def supports_quantity
    return 0.0 unless self.support_variant_indicator
    return self.supports.sum(:quantity)
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
      indirect_expenses_value = production.expenses.sum(:amount).to_d
      distribution_value -= indirect_expenses_value if indirect_expenses_value > 0.0
      #puts "Indirect expenses : #{indirect_expenses_value.inspect}".blue
      #puts "Distribution value : #{distribution_value.inspect}".yellow
      # distribution_value + revenues
      indirect_revenues_value = production.revenues.sum(:amount).to_d
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

    direct_expenses_value = self.expenses.sum(:amount).to_d
    distribution_value -= direct_expenses_value if direct_expenses_value > 0.0

    direct_revenues_value = self.revenues.sum(:amount).to_d
    distribution_value += direct_revenues_value.to_d if direct_revenues_value > 0.0

    global_value += distribution_value.to_d
    return global_value
  end

  def global_cost
    self.direct_budget_amount + self.indirect_budget_amount
  end

  def quandl_dataset
    if Nomen::Varieties[self.cultivation_variant_variety.to_sym] <= :triticum_aestivum
      return 'CHRIS/LIFFE_EBM4'
    elsif Nomen::Varieties[self.cultivation_variant_variety.to_sym] <= :brassica_napus
      return 'CHRIS/LIFFE_ECO4'
    elsif Nomen::Varieties[self.cultivation_variant_variety.to_sym] <= :hordeum_vernum
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
