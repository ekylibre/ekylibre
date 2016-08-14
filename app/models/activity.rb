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
# == Table: activities
#
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  cultivation_variety          :string
#  custom_fields                :jsonb
#  description                  :text
#  family                       :string           not null
#  grading_net_mass_unit_name   :string
#  grading_sizes_indicator_name :string
#  grading_sizes_unit_name      :string
#  id                           :integer          not null, primary key
#  lock_version                 :integer          default(0), not null
#  measure_grading_items_count  :boolean          default(FALSE), not null
#  measure_grading_net_mass     :boolean          default(FALSE), not null
#  measure_grading_sizes        :boolean          default(FALSE), not null
#  name                         :string           not null
#  nature                       :string           not null
#  production_campaign          :string
#  production_cycle             :string           not null
#  production_system_name       :string
#  size_indicator_name          :string
#  size_unit_name               :string
#  support_variety              :string
#  suspended                    :boolean          default(FALSE), not null
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  use_countings                :boolean          default(FALSE), not null
#  use_gradings                 :boolean          default(FALSE), not null
#  use_seasons                  :boolean          default(FALSE)
#  use_tactics                  :boolean          default(FALSE)
#  with_cultivation             :boolean          not null
#  with_supports                :boolean          not null
#

# Activity represents a type of work in the farm like common wheats, pigs,
# fish etc.. Activities are expected to last in years. Activity productions are
# production done inside the given activity with same work method.
class Activity < Ekylibre::Record::Base
  include Attachable
  include Customizable
  refers_to :family, class_name: 'ActivityFamily'
  refers_to :cultivation_variety, class_name: 'Variety'
  refers_to :support_variety, class_name: 'Variety'
  refers_to :size_unit, class_name: 'Unit'
  refers_to :size_indicator, -> { where(datatype: :measure) }, class_name: 'Indicator' # [:population, :working_duration]
  refers_to :grading_net_mass_unit, -> { where(dimension: :distance) }, class_name: 'Unit'
  refers_to :grading_sizes_indicator, -> { where(datatype: :measure) }, class_name: 'Indicator'
  refers_to :grading_sizes_unit, -> { where(dimension: :distance) }, class_name: 'Unit'
  refers_to :production_system
  enumerize :nature, in: [:main, :auxiliary, :standalone], default: :main, predicates: true
  enumerize :production_cycle, in: [:annual, :perennial], predicates: true
  enumerize :production_campaign, in: [:at_cycle_start, :at_cycle_end], default: :at_cycle_end, predicates: true
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

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :family, :nature, :production_cycle, presence: true
  validates :measure_grading_net_mass, :measure_grading_sizes, :suspended, :use_countings, :use_gradings, :with_cultivation, :with_supports, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 500 }
  validates :use_seasons, :use_tactics, inclusion: { in: [true, false] }, allow_blank: true
  # ]VALIDATORS]
  validates :family, inclusion: { in: family.values }
  validates :cultivation_variety, presence: { if: :with_cultivation }
  validates :support_variety, presence: { if: :with_supports }
  validates :name, uniqueness: true
  # validates_associated :productions
  validates :production_campaign, presence: { if: :perennial? }
  validates :grading_net_mass_unit, presence: { if: :measure_grading_net_mass }
  validates :grading_sizes_indicator, :grading_sizes_unit, presence: { if: :measure_grading_sizes }

  scope :actives, -> { availables.where(id: ActivityProduction.where(state: :opened).select(:activity_id)) }
  scope :availables, -> { where.not('suspended') }
  scope :main, -> { where(nature: 'main') }
  scope :of_intervention, lambda { |intervention|
    where(id: TargetDistribution.select(:activity_id).where(target_id: InterventionTarget.select(:product_id).where(intervention_id: intervention)))
  }
  scope :of_campaign, lambda { |campaign|
    if campaign
      c = campaign.is_a?(Campaign) || campaign.is_a?(ActiveRecord::Relation) ? campaign : campaign.map { |c| c.is_a?(Campaign) ? c : Campaign.find(c) }
      prods = where(id: ActivityProduction.select(:activity_id).of_campaign(c))
      budgets = where(id: ActivityBudget.select(:activity_id).of_campaign(c))
      where(id: prods.select(:id) + budgets.select(:id))
    else
      none
    end
  }
  scope :of_cultivation_variety, lambda { |variety|
    where(cultivation_variety: (variety.is_a?(Nomen::Item) ? variety : Nomen::Variety.find(variety)).self_and_children.map(&:name))
  }
  scope :main_of_campaign, ->(campaign) { main.of_campaign(campaign) }
  scope :of_current_campaigns, -> { joins(:campaign).merge(Campaign.current) }
  scope :of_families, proc { |*families|
    where(family: families.flatten.collect { |f| Nomen::ActivityFamily.all(f.to_sym) }.flatten.uniq.map(&:to_s))
  }
  scope :of_family, proc { |family|
    where(family: Nomen::ActivityFamily.all(family))
  }

  accepts_nested_attributes_for :distributions, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :inspection_point_natures, allow_destroy: true
  accepts_nested_attributes_for :inspection_calibration_scales, allow_destroy: true
  accepts_nested_attributes_for :seasons, update_only: true, reject_if: -> (par) { par[:name].blank? }
  accepts_nested_attributes_for :tactics, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :plant_density_abaci, allow_destroy: true, reject_if: :all_blank
  # protect(on: :update) do
  #   productions.any?
  # end

  protect(on: :destroy) do
    productions.any?
  end

  before_validation do
    family = Nomen::ActivityFamily.find(self.family)
    if family
      # FIXME: Need to use nomenclatures to set that data!
      if plant_farming?
        self.with_supports ||= true
        self.support_variety ||= :land_parcel
        self.with_cultivation ||= true
        self.cultivation_variety ||= :plant
        self.size_indicator_name = 'net_surface_area' if size_indicator_name.blank?
        self.size_unit_name = 'hectare' if size_unit_name.blank?
      elsif animal_farming?
        self.with_supports = true
        self.support_variety = :animal_group
        self.with_cultivation = true
        self.cultivation_variety ||= :animal
        self.size_indicator_name = 'members_population' if size_indicator_name.blank?
        self.size_unit_name = 'unity' if size_unit_name.blank?
      else
        self.with_supports = false
        self.with_cultivation = false
      end
      # if with_supports || family.support_variety
      #   self.with_supports = true
      #   self.support_variety = family.support_variety if family.support_variety
      # else
      #   self.with_supports = false
      # end
      # if with_cultivation || family.cultivation_variety
      #   self.with_cultivation = true
      #   self.cultivation_variety = family.cultivation_variety if family.cultivation_variety
      # else
      #   self.with_cultivation = false
      # end
    end
    true
  end

  validate do
    if family = Nomen::ActivityFamily[self.family]
      if with_supports && variety = Nomen::Variety[support_variety] && family.support_variety
        errors.add(:support_variety, :invalid) unless variety <= family.support_variety
      end
      if with_cultivation && variety = Nomen::Variety[cultivation_variety]
        errors.add(:cultivation_variety, :invalid) unless variety <= family.cultivation_variety
      end
    end
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
      production.update_column(:season_id, seasons.first.id) if use_seasons?
      production.update_column(:tactic_id, tactics.first.id) if use_tactics?
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

  [:plant_farming, :animal_farming, :equipment_management, :processing].each do |family_name|
    define_method  family_name.to_s + '?' do
      family && Nomen::ActivityFamily.find(family) <= family_name
    end
  end

  def of_campaign?(campaign)
    productions.of_campaign(campaign).any?
  end

  def size_during(campaign)
    total = productions.of_campaign(campaign).map(&:size).sum
    total = total.in(size_unit) if size_unit
    total
  end

  # Returns human_name of support variety
  def support_variety_name
    item = Nomen::Variety.find(support_variety)
    return nil unless item
    item.human_name
  end

  # Returns human_name of support variety
  def cultivation_variety_name
    item = Nomen::Variety.find(cultivation_variety)
    return nil unless item
    item.human_name
  end

  # Returns human name of activity family
  def family_label
    Nomen::ActivityFamily.find(family).human_name
  end

  # Returns a specific color for the given activity
  def color
    if cultivation_variety
      self.class.color(family, cultivation_variety)
    else
      return '#000000'
    end
  end

  def real_expense_amount(campaign)
    Intervention.of_campaign(campaign).of_activity(self).map(&:cost).compact.sum
  end

  def budget_expenses_amount(campaign)
    budget = budget_of(campaign)
    return 0.0 unless budget
    budget.expenses_amount
  end

  class << self
    # Returns a color for given family and variety
    # short-way solution, can be externalized in mid-way solution
    def color(family, variety)
      colors = { gold: '#FFD700', golden_rod: '#DAA520', yellow: '#FFFF00',
                 orange: '#FF8000', red: '#FF0000', green: '#80BB00',
                 green_yellow: '#ADFF2F', spring_green: '#00FF7F',
                 dark_green: '#006400', lime: '#00FF00', dark_turquoise: '#00FFFF',
                 blue: '#0000FF', purple: '#BF00FF', gray: '#A4A4A4',
                 slate_gray: '#708090', dark_magenta: '#8B008B', violet: '#EE82EE',
                 teal: '#008080', fuchsia: '#FF00FF', brown: '#6A2B1A' }
      activity_family = Nomen::ActivityFamily.find(family)
      variety = Nomen::Variety.find(variety)
      crop_sets = []
      # if there no variety (no land cases)
      if variety
        crop_sets = Nomen::CropSet.select do |i|
          i.varieties.detect { |v| variety <= v }
        end.map { |i| i.name.to_sym }
      end
      return colors[:gray] unless activity_family
      if activity_family <= :plant_farming && (variety || crop_sets.any?)
        # MEADOW
        if crop_sets.include?(:meadow)
          colors[:dark_green]
        # CEREALS
        elsif crop_sets.include?(:cereals)
          if variety <= :zea || variety <= :sorghum
            colors[:orange]
          elsif variety <= :hordeum || variety <= :avena || variety <= :secale
            '#EEDD99'
          elsif variety <= :triticum || variety <= :triticosecale
            colors[:gold]
          else
            colors[:golden_rod]
          end
        # OILSEED
        elsif crop_sets.include?(:oleaginous)
          colors[:green_yellow]
        # PROTEINS
        elsif crop_sets.include?(:proteaginous)
          colors[:teal]
        # FIBER
        elsif variety <= :linum ||
              variety <= :cannabis
          colors[:slate_gray]
        # LEGUMINOUS
        elsif crop_sets.include?(:leguminous)
          colors[:lime]
        elsif crop_sets.include?(:vegetables)
          colors[:red]
        elsif crop_sets.include?(:arboricultural)
          colors[:blue]
        # VINE
        elsif variety <= :vitaceae
          colors[:purple]
        elsif crop_sets.include?(:aromatics_and_medicinals)
          colors[:dark_turquoise]
        elsif crop_sets.include?(:tropicals)
          colors[:fuchsia]
        elsif variety <= :nicotiana
          colors[:dark_turquoise]
        else
          colors[:green]
        end
      elsif activity_family <= :animal_farming
        colors[:brown]
      elsif activity_family <= :administering
        colors[:brown]
      elsif activity_family <= :tool_maintaining
        colors[:blue]
      else
        colors[:gray]
      end
    end

    # Find nearest family on cultivation variety and support variety
    def best_for_cultivation(family, cultivation_variety)
      return nil unless any?
      searched = Nomen::Variety.find(cultivation_variety)
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
      if cultivation_variety.present?
        family = :plant_farming if cultivation_variety <= :plant
        family = :animal_farming if cultivation_variety <= :animal
        family = :tool_maintaining if cultivation_variety <= :equipment ||
                                      cultivation_variety <= :building ||
                                      cultivation_variety <= :building_division
        family = :wine_making if cultivation_variety <= :wine
      end
      family ||= :administering
      Nomen::ActivityFamily.find(family)
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
    productions.of_campaign(campaign).collect { |p| p.interventions.map(&:working_duration) }.flatten.compact.sum
  end

  def is_of_family?(family)
    Nomen::ActivityFamily[self.family] <= family
  end

  def unit_choices
    [:items, :mass]
      .reject { |e| e == :items && !measure_grading_items_count }
      .reject { |e| e == :mass && !measure_grading_net_mass }
end

  def unit_preference(user, unit = nil)
    unit_preference_name = "activity_#{id}_inspection_view_unit"
    user.prefer!(unit_preference_name, unit.to_sym) if unit.present?
    pref = user.preference(unit_preference_name).value
    pref ||= :mass
    pref = unit_choices.find { |c| c.to_sym == pref.to_sym }
    pref ||= unit_choices.first
  end
end
