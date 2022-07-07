# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: activities
#
#  codes                          :jsonb
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  cultivation_variety            :string
#  custom_fields                  :jsonb
#  description                    :text
#  family                         :string           not null
#  grading_net_mass_unit_name     :string
#  grading_sizes_indicator_name   :string
#  grading_sizes_unit_name        :string
#  id                             :integer          not null, primary key
#  life_duration                  :decimal(5, 2)
#  lock_version                   :integer          default(0), not null
#  measure_grading_items_count    :boolean          default(FALSE), not null
#  measure_grading_net_mass       :boolean          default(FALSE), not null
#  measure_grading_sizes          :boolean          default(FALSE), not null
#  name                           :string           not null
#  nature                         :string           not null
#  production_cycle               :string           not null
#  production_nature_id           :integer
#  production_started_on          :date
#  production_started_on_year     :integer
#  production_stopped_on          :date
#  production_stopped_on_year     :integer
#  production_system_name         :string
#  size_indicator_name            :string
#  size_unit_name                 :string
#  start_state_of_production_year :integer
#  support_variety                :string
#  suspended                      :boolean          default(FALSE), not null
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#  use_countings                  :boolean          default(FALSE), not null
#  use_gradings                   :boolean          default(FALSE), not null
#  use_seasons                    :boolean          default(FALSE)
#  use_tactics                    :boolean          default(FALSE)
#  with_cultivation               :boolean          not null
#  with_supports                  :boolean          not null
#

# Activity represents a type of work in the farm like common wheats, pigs,
# fish etc.. Activities are expected to last in years. Activity productions are
# production done inside the given activity with same work method.
class Activity < ApplicationRecord
  include Attachable
  include Customizable
  include Activities::LeftJoinable
  include Activities::Colorable

  refers_to :family, class_name: 'ActivityFamily', predicates: true
  refers_to :cultivation_variety, class_name: 'Variety'
  refers_to :support_variety, class_name: 'Variety'
  refers_to :size_unit, class_name: 'Unit'
  refers_to :size_indicator, -> { where(datatype: :measure) }, class_name: 'Indicator' # [:population, :working_duration]
  refers_to :grading_net_mass_unit, -> { where(dimension: :distance) }, class_name: 'Unit'
  refers_to :grading_sizes_indicator, -> { where(datatype: :measure) }, class_name: 'Indicator'
  refers_to :grading_sizes_unit, -> { where(dimension: :distance) }, class_name: 'Unit'
  refers_to :production_system
  enumerize :nature, in: %i[main auxiliary standalone], default: :main, predicates: true
  enumerize :production_cycle, in: %i[annual perennial], default: :annual, predicates: true
  enumerize :distribution_key, in: %i[gross_margin percentage equipment_intervention_duration], default: :gross_margin, predicates: true
  with_options dependent: :destroy, inverse_of: :activity do
    has_many :budgets, class_name: 'ActivityBudget'
    has_many :distributions, class_name: 'ActivityDistribution'
    has_many :productions, class_name: 'ActivityProduction'
    has_many :seasons, class_name: 'ActivitySeason'
    has_many :tactics, class_name: 'ActivityTactic'
    has_many :inspections, class_name: 'Inspection'
    has_many :plant_density_abaci, class_name: 'PlantDensityAbacus'
    has_many :inspection_point_natures, class_name: 'ActivityInspectionPointNature'
    has_many :inspection_calibration_scales, class_name: 'ActivityInspectionCalibrationScale'
    has_many :inspection_calibration_natures, class_name: 'ActivityInspectionCalibrationNature', through: :inspection_calibration_scales, source: :natures
  end
  has_many :supports, through: :productions
  # planning
  has_many :default_tactics, -> { default }, class_name: 'ActivityTactic', inverse_of: :activity
  has_many :associations_intervention_templates, class_name: 'InterventionTemplateActivity', foreign_key: :activity_id
  has_many :intervention_templates, through: :associations_intervention_templates

  belongs_to :production_nature, primary_key: :reference_name, class_name: 'MasterCropProduction', foreign_key: :reference_name

  has_and_belongs_to_many :interventions
  has_and_belongs_to_many :campaigns

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :family, :nature, :production_cycle, presence: true
  validates :isacompta_analytic_code, length: { maximum: 2 }, allow_blank: true
  validates :life_duration, numericality: { greater_than: -1_000, less_than: 1_000 }, allow_blank: true
  validates :measure_grading_net_mass, :measure_grading_sizes, :suspended, :use_countings, :use_gradings, :with_cultivation, :with_supports, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 500 }
  validates :production_started_on, :production_stopped_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years }, type: :date }, allow_blank: true
  validates :production_started_on_year, :production_stopped_on_year, :start_state_of_production_year, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :reference_name, length: { maximum: 500 }, allow_blank: true
  validates :use_seasons, :use_tactics, inclusion: { in: [true, false] }, allow_blank: true
  # ]VALIDATORS]
  validates :cultivation_variety, presence: true, if: -> { Onoma::ActivityFamily[family] && Onoma::ActivityFamily[family].cultivation_variety.present? }
  validates :family, inclusion: { in: family.values }
  validates :cultivation_variety, presence: { if: :with_cultivation }
  validates :support_variety, presence: { if: :with_supports }
  validates :name, uniqueness: true
  # validates_associated :productions
  validates :grading_net_mass_unit, presence: { if: :measure_grading_net_mass }
  validates :grading_sizes_indicator, :grading_sizes_unit, presence: { if: :measure_grading_sizes }
  validates_length_of :isacompta_analytic_code, is: 2, if: :isacompta_analytic_code?

  with_options if: -> { perennial? && (plant_farming? || vine_farming?) } do
    validates :start_state_of_production_year, :life_duration, presence: true
    validates :production_stopped_on_year, inclusion: { in: [0], message: :invalid }
    validates :production_cycle_length, presence: true
    validate :validate_production_cycle_period_presence
  end

  validates :life_duration, presence: true, if: -> { animal_farming? }
  validates :start_state_of_production_year, :life_duration, absence: true, if: -> { annual? && !plant_farming? && !vine_farming? }
  validates :production_nature, absence: true, if: -> { !vine_farming? && !plant_farming? }

  validates_associated :tactics
  accepts_nested_attributes_for :tactics, allow_destroy: true

  scope :actives, -> { availables.where(id: ActivityProduction.where(state: :opened).select(:activity_id)) }
  scope :availables, -> { where.not('suspended') }
  scope :with_production_dates, -> do
    where.not(production_started_on: nil,
              production_started_on_year: nil,
              production_stopped_on: nil,
              production_stopped_on_year: nil)
  end
  scope :without_production_dates, -> do
    where(production_started_on: nil)
      .or(where(production_started_on_year: nil))
      .or(where(production_stopped_on: nil))
      .or(where(production_stopped_on_year: nil))
  end
  scope :main, -> { where(nature: 'main') }
  scope :auxiliary, -> { where(nature: 'auxiliary') }

  scope :of_support_variety, ->(variety) { where(support_variety: variety) }

  scope :of_campaign, ->(campaign) {
    if campaign
      c = campaign.is_a?(Campaign) || campaign.is_a?(ActiveRecord::Relation) || campaign.is_a?(String) ? campaign : campaign.map { |c| c.is_a?(Campaign) ? c : Campaign.find(c) }
      where(id: HABTM_Campaigns.select(:activity_id).where(campaign: c))
    else
      none
    end
  }
  scope :with_cultivation_variety, lambda { |variety|
    where(cultivation_variety: (variety.is_a?(Onoma::Item) ? variety : Onoma::Variety.find(variety)).self_and_parents.map(&:name))
  }
  scope :of_cultivation_variety, lambda { |variety|
    where(cultivation_variety: (variety.is_a?(Onoma::Item) ? variety : Onoma::Variety.find(variety)).self_and_children.map(&:name))
  }
  scope :main_of_campaign, ->(campaign) { main.of_campaign(campaign) }
  scope :of_current_campaigns, -> { joins(:campaign).merge(Campaign.current) }
  scope :of_families, ->(*families) {
    where(family: families.flatten.collect { |f| Onoma::ActivityFamily.all(f.to_sym) }.flatten.uniq.map(&:to_s))
  }
  scope :of_family, ->(family) { where(family: Onoma::ActivityFamily.all(family)) }
  scope :with_production_nature, -> {where.not(reference_name: nil)}

  accepts_nested_attributes_for :distributions, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :inspection_point_natures, allow_destroy: true
  accepts_nested_attributes_for :inspection_calibration_scales, allow_destroy: true
  accepts_nested_attributes_for :seasons, update_only: true, reject_if: ->(par) { par[:name].blank? }
  accepts_nested_attributes_for :tactics, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :plant_density_abaci, allow_destroy: true, reject_if: :all_blank

  attr_reader :production_cycle_period

  def start_state_of_production
    production_nature.start_state_of_production.fetch(start_state_of_production_year) if perennial? && activity.production_nature.present?
  end

  protect(on: :destroy) do
    productions.any?
  end

  delegate :usage, to: :production_nature, allow_nil: true

  after_initialize :set_default

  def set_default
    case family
    when 'vine_farming'
      vine_default_production = MasterCropProduction.find_by(specie: 'vitis')

      self.reference_name ||= vine_default_production.reference_name
      self.cultivation_variety ||= 'vitis'
      self.start_state_of_production_year ||= 3
      self.life_duration ||= vine_default_production.life_duration.parts[:years]
      self.production_started_on ||= vine_default_production.started_on
      self.production_stopped_on ||= vine_default_production.stopped_on
      self.production_started_on_year ||= -1
      self.production_stopped_on_year ||= 0
      self.production_cycle = 'perennial'
    when 'animal_farming'
      self.production_cycle = 'perennial'
      self.life_duration ||= 20
      self.production_stopped_on_year ||= 0
    end
  end

  before_validation do
    item = Onoma::ActivityFamily.find(family)
    if item
      if item.support_variety.present?
        self.with_supports = true
        self.support_variety = item.support_variety
      else
        self.with_supports = false
      end
      self.with_cultivation = item.cultivation_variety.present?
    end
    if plant_farming? || vine_farming?
      self.size_indicator_name = 'net_surface_area'
      self.size_unit_name = 'hectare'
    elsif animal_farming? || tool_maintaining?
      self.size_indicator_name = 'members_population'
      self.size_unit_name = 'unity'
    elsif wine_making?
      self.size_indicator_name = 'net_volume'
      self.size_unit_name = 'unity'
    elsif processing?
      self.size_indicator_name = 'net_mass'
      self.size_unit_name = 'unity'
    end
    self.cultivation_variety ||= item.cultivation_variety if with_cultivation

    set_production_relative_year
  end

  # production_started_on and production_stopped_on year is relative to campaign. Set year value to 2000.
  def set_production_relative_year
    if production_started_on.present? && production_stopped_on.present?
      self.production_started_on = production_started_on.change(year: 2000)
      self.production_stopped_on = production_stopped_on.change(year: 2000)
    end
  end

  validate do
    validate_stopped_on_after_started_on
  end

  def production_cycle_length
    if production_started_on.present? && production_stopped_on.present? && production_started_on_year.present? && production_stopped_on_year.present?
      production_stopped_on.change(year: production_stopped_on.year + production_stopped_on_year ) - production_started_on.change(year: production_started_on.year + production_started_on_year )
    end
  end

  def validate_stopped_on_after_started_on
    if production_cycle_length.present? && production_cycle_length < 0
      errors.add :production_cycle_period, :start_date_before_end_date
    end
  end

  def validate_production_cycle_period_presence
    if production_cycle_length.nil?
      errors.add :production_cycle_period, :blank
    end
  end

  validate do
    errors.add :use_gradings, :checked_off_with_inspections if inspections.any? && !use_gradings
    errors.add :use_gradings, :checked_without_measures if use_gradings && !measure_something?
    errors.add :family, :productions_present if changed.include?('family') && productions.exists?

    next unless family_item = Onoma::ActivityFamily[family]

    if with_supports && variety = Onoma::Variety[support_variety] && family_item.support_variety
      errors.add(:support_variety, :invalid) unless variety <= family_item.support_variety
    end
    next unless with_cultivation && variety = Onoma::Variety[cultivation_variety]
    next unless family_item.cultivation_variety.present?

    errors.add(:cultivation_variety, :invalid) unless variety <= family_item.cultivation_variety
    true
  end

  before_save do
    self.support_variety = nil unless with_supports
    self.cultivation_variety = nil unless with_cultivation
    self.use_seasons = nil unless seasons.any?
    self.use_tactics = nil unless tactics.any?
  end

  after_save do
    productions.each(&:update_names)
  end

  after_save do
    productions.each do |production|
      production.update_column(:season_id, seasons.first.id) if use_seasons? && seasons.any? && production.season_id.nil?
      production.update_column(:tactic_id, tactics.first.id) if use_tactics? && tactics.any? && production.tactic_id.nil?
    end
    if auxiliary? && distributions.any?
      total = distributions.sum(:affectation_percentage)
      if total != 100
        sum = 0
        distributions.each do |distribution|
          percentage = (distribution.affectation_percentage * 100.0 / total).round(2)
          sum += percentage
          distribution.update_column(:affectation_percentage, percentage)
        end
        if sum != 100
          distribution = distributions.last
          distribution.update_column(:affectation_percentage, distribution.affectation_percentage + (100 - sum))
        end
      end
    else
      distributions.clear
    end
  end

  def interventions
    Intervention.of_activity(self)
  end

  def intervention_parameters
    InterventionParameter.of_activity(self)
  end

  def budget_of(campaign)
    return nil unless campaign

    budgets.find_by(campaign: campaign)
  end

  def count_during(campaign)
    productions.of_campaign(campaign).count
  end

  def used_during?(campaign)
    productions.of_campaign(campaign).any?
  end

  Onoma::ActivityFamily.find_each do |base_family|
    define_method base_family.name.to_s + '?' do
      family && Onoma::ActivityFamily.find(family) <= base_family
    end
  end

  def of_campaign?(campaign)
    productions.of_campaign(campaign).any?
  end

  def size_during(campaign)
    if animal_farming?
      total = productions.of_campaign(campaign).map do |production|
        viewed_at = Time.zone.now.change(year: campaign.harvest_year)
        production.support&.members_count(viewed_at)
      end.compact.sum(0.0)
    else
      total = productions.of_campaign(campaign).map(&:size).compact.sum
    end
    if size_unit
      total.in(size_unit)
    else
      total
    end
  end

  # Returns human_name of support variety
  def support_variety_name
    item = Onoma::Variety.find(support_variety)
    return nil unless item

    item.human_name
  end

  # Returns human_name of support variety
  def cultivation_variety_name
    item = Onoma::Variety.find(cultivation_variety)
    return nil unless item

    item.human_name
  end

  # Returns human name of activity family
  def family_label
    Onoma::ActivityFamily.find(family).human_name
  end

  # Returns a specific color for the given activity
  def color
    self.class.color(family, cultivation_variety)
  end

  def real_expense_amount(campaign)
    Intervention.of_campaign(campaign).of_activity(self).map(&:cost).compact.sum
  end

  def budget_expenses_amount(campaign)
    budget = budget_of(campaign)
    return 0.0 unless budget

    budget.expenses_amount
  end

  def quandl_dataset
    if Onoma::Variety[self.cultivation_variety.to_sym] <= :triticum_aestivum
      'CHRIS/LIFFE_EBM4'
    elsif Onoma::Variety[self.cultivation_variety.to_sym] <= :brassica_napus
      'CHRIS/LIFFE_ECO4'
    elsif Onoma::Variety[self.cultivation_variety.to_sym] <= :hordeum_hexastichum
      'CHRIS/ICE_BW2'
    elsif Onoma::Variety[self.cultivation_variety.to_sym] <= :zea
      'CHRIS/LIFFE_EMA10'
    end
  end

  def organic_farming?
    production_system_name == "organic_farming"
  end

  class << self
    # Find nearest family on cultivation variety and support variety
    def best_for_cultivation(family, cultivation_variety)
      return nil unless any?

      searched = Onoma::Variety.find(cultivation_variety)
      activities = of_family(family).select do |activity|
        searched <= activity.cultivation_variety
      end
      return activities.first if activities.count == 1

      best = nil
      littlest_degree_of_kinship = nil
      activities.each do |a|
        degree = searched.degree_of_kinship_with(a.cultivation_variety)
        next unless degree

        if littlest_degree_of_kinship.nil? || littlest_degree_of_kinship > degree
          littlest_degree_of_kinship = degree
          best = a
        end
      end
      best
    end

    # Find nearest family on cultivation variety and support variety
    def find_best_family(cultivation_variety, _support_variety = nil)
      cv = Onoma::Variety.find(cultivation_variety)
      if cv.present?
        family = :plant_farming if cv <= :plant
        family = :vine_farming if cv <= :vitis
        family = :animal_farming if cv <= :animal
        family = :tool_maintaining if cv <= :equipment ||
          cv <= :building ||
          cv <= :building_division
        family = :wine_making if cv <= :wine
      end
      family ||= :administering
      Onoma::ActivityFamily.find(family)
    end
  end

  def support_shape_area(*campaigns)
    options = campaigns.extract_options!
    productions.of_campaign(*campaigns).map(&:support_shape_area)
               .compact.sum.in(options[:unit] || :square_meter)
  end

  alias net_surface_area support_shape_area

  def interventions_duration(campaign)
    # productions.of_campaign(campaign).map(&:duration).compact.sum
    productions.of_campaign(campaign).collect { |p| p.interventions.real.sum(:working_duration) }.sum
  end

  def is_of_family?(family)
    Onoma::ActivityFamily[self.family] <= family
  end

  def inspectionable?
    use_gradings && inspection_calibration_scales.any? && inspections.any?
  end

  def measure_something?
    measure_grading_items_count || measure_grading_net_mass || measure_grading_sizes
  end

  def unit_choices
    %i[items_count net_mass]
      .reject { |e| e == :items_count && !measure_grading_items_count }
      .reject { |e| e == :net_mass && !measure_grading_net_mass }
  end

  def unit_preference(user, unit = nil)
    unit_preference_name = "activity_#{id}_inspection_view_unit"
    user.prefer!(unit_preference_name, unit.to_sym) if unit.present?
    pref = user.preference(unit_preference_name).value
    pref ||= :items_count
    pref = unit_choices.find { |c| c.to_sym == pref.to_sym }
    pref ||= unit_choices.first
  end

  # @return [Interger] rank number of the next activity_production
  def productions_next_rank_number
    (productions.maximum(:rank_number) || 0) + 1
  end

  def technical_workflow(campaign)
    tactic = tactics.find_by(campaign_id: campaign.id, default: true)

    return tactic.technical_workflow if tactic.present? && tactic.technical_workflow.present?

    TechnicalWorkflow.for_activity(self).first
  end
end
