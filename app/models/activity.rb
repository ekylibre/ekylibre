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
# == Table: activities
#
#  color               :string
#  created_at          :datetime         not null
#  creator_id          :integer
#  cultivation_variety :string
#  description         :text
#  family              :string           not null
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string           not null
#  nature              :string           not null
#  size_indicator      :string
#  size_unit           :string
#  support_variety     :string
#  suspended           :boolean          default(FALSE), not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#  with_cultivation    :boolean          not null
#  with_supports       :boolean          not null
#

# Activity represents a type of work in the farm like common wheats, pigs,
# fish etc.. Activities are expected to last in years. Activity productions are
# production done inside the given activity with same work method.
class Activity < Ekylibre::Record::Base
  include Attachable
  refers_to :family, class_name: 'ActivityFamily'
  refers_to :cultivation_variety, class_name: 'Variety'
  refers_to :support_variety, class_name: 'Variety'
  # refers_to :size_unit, class_name: 'Unit'
  # refers_to :size_indicator, -> { where(datatype: :measure) }, class_name: 'Indicator' # [:population, :working_duration]
  enumerize :nature, in: [:main, :auxiliary, :standalone], default: :main, predicates: true
  has_many :budgets, class_name: 'ActivityBudget'
  has_many :expenses, -> { where(direction: :expense).includes(:variant) }, class_name: 'ActivityBudget', inverse_of: :activity
  has_many :revenues, -> { where(direction: :revenue).includes(:variant) }, class_name: 'ActivityBudget', inverse_of: :activity
  has_many :distributions, class_name: 'ActivityDistribution', dependent: :destroy, inverse_of: :activity
  has_many :productions, class_name: 'ActivityProduction', dependent: :destroy, inverse_of: :activity
  has_many :supports, through: :productions

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :suspended, :with_cultivation, :with_supports, in: [true, false]
  validates_presence_of :family, :name, :nature
  # ]VALIDATORS]
  validates_inclusion_of :family, in: family.values, allow_nil: true
  validates_presence_of :family
  validates_presence_of :cultivation_variety, if: :with_cultivation
  validates_presence_of :support_variety, if: :with_supports
  validates_uniqueness_of :name
  validates_associated :expenses, :revenues
  validates_associated :productions

  scope :actives, -> { availables.where(id: ActivityProduction.opened) }
  scope :availables, -> { where.not('suspended') }
  scope :main, -> { where(nature: 'main') }
  scope :of_intervention, lambda { |intervention|
    where(id: TargetDistribution.select(:activity_id).where(target_id: InterventionTarget.select(:product_id).where(intervention_id: intervention)))
  }
  scope :of_campaign, lambda { |campaign|
    where(id: ActivityProduction.select(:activity_id).of_campaign(campaign.is_a?(Campaign) ? campaign : campaign.find(campaign.map(&:id))))
  }
  scope :of_cultivation_variety, lambda { |variety|
    where(cultivation_variety: Nomen::Variety.find(variety).all)
  }
  scope :main_of_campaign, ->(campaign) { main.of_campaign(campaign) }
  scope :of_current_campaigns, -> { joins(:campaign).merge(Campaign.current) }
  scope :of_families, proc { |*families|
    where(family: families.flatten.collect { |f| Nomen::ActivityFamily.all(f.to_sym) }.flatten.uniq.map(&:to_s))
  }

  accepts_nested_attributes_for :expenses, :revenues, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :distributions, reject_if: :all_blank, allow_destroy: true

  protect(on: :update) do
    productions.any?
  end

  protect(on: :destroy) do
    productions.any? || interventions.any?
  end

  before_validation do
    family = Nomen::ActivityFamily.find(self.family)
    if family
      if with_supports.nil?
        if family.support_variety
          self.with_supports = true
          self.support_variety = family.support_variety
        else
          self.with_supports = false
        end
      end
      if with_cultivation.nil?
        if family.cultivation_variety
          self.with_cultivation = true
          self.cultivation_variety = family.cultivation_variety
        else
          self.with_cultivation = false
        end
      end
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

  before_create do
    self.color ||= find_color
  end

  before_save do
    self.support_variety = nil unless with_supports
    self.cultivation_variety = nil unless with_cultivation
  end

  after_save do
    if self.auxiliary? && distributions.any?
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

  def casts
    InterventionCast.of_activity(self)
  end

  def count_during(campaign)
    productions.of_campaign(campaign).count
  end

  def size_during(campaign)
    total = productions.of_campaign(campaign).pluck(:size_value).sum
    # total = total.in(size_unit) if size_unit
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

  # Returns a color for each activity depending on families
  # FIXME: Only refers to activity family to prevent
  # short-way solution must be externalized in mid-way solution
  def find_color
    colors = { gold: '#FFD700', golden_rod: '#DAA520', yellow: '#FFFF00',
               orange: '#FF8000', red: '#FF0000', green: '#80FF00',
               spring_green: '#00FF7F', dark_green: '#006400',
               dark_turquoise: '#00FFFF', blue: '#0000FF', purple: '#BF00FF',
               gray: '#A4A4A4', dark_magenta: '#8B008B', violet: '#EE82EE',
               teal: '#008080', fuchsia: '#FF00FF', brown: '#6A2B1A' }
    activity_family = Nomen::ActivityFamily.find(family)
    variety = Nomen::Variety.find(cultivation_variety)
    return colors[:gray] unless activity_family
    if activity_family <= :vegetal_crops && variety
      # ARBO, FRUIT = BLUE
      if activity_family <= :arboriculture
        colors[:blue]
      elsif activity_family <= :field_crops
        # level 3 - category - CEREALS = GOLD/YELLOW/ORANGE
        if activity_family <= :cereal_crops
          # level 4 - variety
          if variety <= :zea || variety <= :sorghum
            colors[:orange]
          elsif variety <= :hordeum
            colors[:yellow]
          else
            colors[:gold]
          end
        # level 3 - category - BEETS / POTATO = VIOLET
        elsif activity_family <= :beet_crops
          colors[:violet]
        # level 3 - category - FODDER = SPRING GREEN
        elsif activity_family <= :fodder_crops ||
              activity_family <= :fallow_land
          colors[:dark_green]
        elsif activity_family <= :meadow
          colors[:dark_green]
        # level 3 - category - PROTEINS = TEAL
        elsif activity_family <= :protein_crops
          colors[:teal]
        # level 3 - category - OILSEED = GOLDEN ROD
        elsif activity_family <= :oilseed_crops
          colors[:golden_rod]
        # level 3 - category - BEETS / POTATO = VIOLET
        elsif activity_family <= :potato_crops
          colors[:violet]
        # level 3 - category - AROMATIC, TOBACCO, HEMP = TURQUOISE
        elsif variety <= :nicotiana ||
              variety <= :cannabis
          colors[:dark_turquoise]
        else
          colors[:gray]
        end
      elsif activity_family <= :aromatic_and_medicinal_plants
        colors[:dark_turquoise]
      # level 3 - category - FLOWER = FUCHSIA
      elsif activity_family <= :flower_crops
        colors[:fuchsia]
      # level 3 - category - ARBO, FRUIT = BLUE
      elsif activity_family <= :fruits_crops
        colors[:blue]
      # level 3 - category - MARKET = RED
      elsif activity_family <= :market_garden_crops
        colors[:red]
      else
        colors[:gray]
      end
    elsif activity_family <= :animal_farming
      colors[:brown]
    else
      colors[:gray]
    end
  end

  class << self
    def find_best_family(cultivation_variety, support_variety)
      rankings = Nomen::ActivityFamily.list.inject({}) do |hash, item|
        valid = true
        valid = false unless !cultivation_variety == !item.cultivation_variety
        distance = 0
        if valid && cultivation_variety
          if Nomen::Variety[cultivation_variety] <= item.cultivation_variety
            distance += Nomen::Variety[cultivation_variety].depth - Nomen::Variety[item.cultivation_variety].depth
          else
            valid = false
          end
        end
        if valid && support_variety
          if Nomen::Variety[support_variety] <= item.support_variety
            distance += Nomen::Variety[support_variety].depth - Nomen::Variety[item.support_variety].depth
          else
            valid = false
          end
        end
        hash[item.name] = distance if valid
        hash
      end.sort { |a, b| a.second <=> b.second }
      if best_choice = rankings.first
        return Nomen::ActivityFamily.find(best_choice.first)
      end
      nil
    end
  end

  def shape_area(*campaigns)
    productions.of_campaign(campaigns).map(&:shape_area).compact.sum
  end

  def net_surface_area(*campaigns)
    surface = []
    for campaign in campaigns
      surface << productions.of_campaign(campaign).map(&:net_surface_area).compact.sum
    end
    surface.compact.sum
  end

  def area(*campaigns)
    # raise "NO AREA"
    ActiveSupport::Deprecation.warn("#{self.class.name}#area is deprecated. Please use #{self.class.name}#net_surface_area instead.")
    net_surface_area(*campaigns)
  end

  def interventions_duration(*campaigns)
    productions.of_campaign(campaigns).map(&:duration).compact.sum
  end

  def is_of_family?(family)
    Nomen::ActivityFamily[self.family] <= family
  end
end
