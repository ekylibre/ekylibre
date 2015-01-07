# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
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
#  homogeneous_expenses :boolean
#  homogeneous_revenues :boolean
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  position             :integer
#  started_at           :datetime
#  state                :string(255)      not null
#  static_support       :boolean          not null
#  stopped_at           :datetime
#  support_variant_id   :integer
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variant_id           :integer
#  working_indicator    :string(255)
#  working_unit         :string(255)
#
class Production < Ekylibre::Record::Base
  enumerize :state, in: [:draft, :validated], default: :draft
  enumerize :working_unit, in: Nomen::Units.all
  enumerize :working_indicator, in: Nomen::Indicators.all
  belongs_to :activity
  belongs_to :campaign
  belongs_to :variant, class_name: "ProductNatureVariant"
  belongs_to :support_variant, class_name: "ProductNatureVariant"
  # belongs_to :area_unit, class_name: "Unit"
  has_many :budgets
  has_many :distributions, class_name: "AnalyticDistribution"
  has_many :supports, class_name: "ProductionSupport", inverse_of: :production, dependent: :destroy
  has_many :markers, through: :supports, class_name: "ProductionSupportMarker"
  has_many :interventions, inverse_of: :production
  has_many :storages, through: :supports
  has_many :casts, through: :interventions, class_name: "InterventionCast"
  # has_many :selected_manure_management_plan_zones, class_name: "ManureManagementPlanZone", through: :supports
  # has_many :land_parcel_groups, :through => :supports, class_name: "Product" #, :conditions => {:variety => "land_parcel_group"}

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_length_of :name, :state, :working_indicator, :working_unit, allow_nil: true, maximum: 255
  validates_inclusion_of :static_support, in: [true, false]
  validates_presence_of :activity, :campaign, :name, :state
  #]VALIDATORS]
  # validates_presence_of :product_nature, if: :activity_main?

  alias_attribute :label, :name
  alias_attribute :product_variant, :variant

  delegate :name, :variety, to: :variant, prefix: true

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    where(campaign_id: campaigns.map(&:id))
  }
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


  accepts_nested_attributes_for :supports, :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :budgets, reject_if: :all_blank, allow_destroy: true

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
    self.state ||= self.class.state_machine.initial_state(self)
  end

  before_validation do
    if self.activity and self.campaign and self.variant
      self.name = tc(:name, state: self.state_label, activity: self.activity.name, variant: self.variant.name, campaign: self.campaign.name)
    elsif self.activity and self.campaign
      self.name = tc(:name_without_variant, state: self.state_label, activity: self.activity.name, campaign: self.campaign.name)
    end
  end

  def activity_main?
    self.activity and self.activity_main?
  end

  def has_active_product?
    self.variant.nature.active?
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # Prints human name of current production
  def state_label
    self.class.state_label(self.state)
  end

  def shape_area
    if self.static_support?
      return self.supports.map(&:storage_shape_area).compact.sum
    else
      return 0.0.in_square_meter
    end
  end

  def net_surface_area
    if self.static_support? and self.supports.any?
      return self.supports.map(&:storage_net_surface_area).compact.sum
    end
    return 0.0.in_square_meter
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


  def active?
    if self.activity.fallow_land?
      return false
    else
      return true
    end
  end

end
