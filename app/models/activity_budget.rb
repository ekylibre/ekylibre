
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: activity_budgets
#
#  activity_id  :integer          not null
#  campaign_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  currency     :string           not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ActivityBudget < Ekylibre::Record::Base
  belongs_to :activity
  belongs_to :campaign
  with_options class_name: 'ActivityBudgetItem', inverse_of: :activity_budget do
    has_many :items, dependent: :destroy
    has_many :expenses, -> { expenses }
    has_many :revenues, -> { revenues }
  end
  has_many :journal_entry_items, dependent: :nullify
  has_many :purchase_items, dependent: :nullify
  has_many :sale_items, dependent: :nullify

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :currency, presence: true, length: { maximum: 500 }
  validates :activity, :campaign, presence: true
  # ]VALIDATORS]
  validates_associated :expenses, :revenues

  scope :opened, -> { where(activity: Activity.actives) }
  scope :of_campaign, ->(campaign) { where(campaign: campaign) }
  scope :of_activity, ->(activity) { where(activity: activity) }

  accepts_nested_attributes_for :expenses, :revenues, reject_if: :all_blank, allow_destroy: true

  delegate :name, to: :activity, prefix: true
  delegate :name, to: :campaign, prefix: true
  delegate :size_indicator, :size_unit, to: :activity

  before_validation on: :create do
    self.currency ||= Preference[:currency]
  end

  def expenses_amount
    expenses.sum(:amount)
  end

  def revenues_amount
    revenues.sum(:amount)
  end

  def name
    tc(:name, activity_name: activity_name, campaign_name: campaign_name)
  end

  def currency_precision
    Nomen::Currency.find(currency).precision
  end

  def productions
    return ActivityProduction.none if activity.nil?
    activity.productions.of_campaign(campaign)
  end

  def any_production?
    productions.any?
  end

  def productions_size
    productions.map(&:size_value).sum
  end

  delegate :count, to: :productions, prefix: true

  delegate :count, to: :productions, prefix: true

  def computation_methods
    list = []
    if productions_size.to_f.nonzero?
      list << :per_working_unit
      list << :per_production
    elsif productions_count.to_f.nonzero?
      list << :per_production
    end
    list << :per_campaign
    list
  end

  # Duplicate current budget in given activity and campaign
  def duplicate!(activity, campaign)
    budget = ActivityBudget.find_or_create_by!(activity: activity, campaign: campaign)
    items.each do |item|
      item.duplicate!(activity_budget: budget)
    end
    budget
  end

  # return estimate yield from revenues item for given variety
  def estimate_yield(variety, options = {})
    # set default parameter if theres no one given
    yield_unit = Nomen::Unit.find(options[:unit] || :quintal_per_hectare)
    unless yield_unit
      raise ArgumentError, "Cannot find unit for yield estimate: #{options[:unit].inspect}"
    end

    Nomen::Variety.find!(variety)

    r = []
    revenues.where(variant: ProductNatureVariant.of_variety(variety)).find_each do |item|
      next if item.variant_indicator == 'working_period'
      quantity_unit = item.variant_unit
      quantity = if item.variant_indicator == 'population' && item.variant.frozen_indicators.detect { |i| i <= :net_mass }
                   quantity_unit = :quintal
                   item.quantity * item.variant.net_mass.to_f(quantity_unit)
                 else
                   item.quantity
                 end
      # TODO: do dimensional analysis to find exiting unit in matching dimension if necessary
      item_unit = Nomen::Unit.find("#{quantity_unit}_per_#{activity.size_unit.name}")
      next unless item_unit
      next unless item_unit.dimension == yield_unit.dimension
      harvest_yield = if item.per_working_unit?
                        quantity
                      elsif item.per_production?
                        next if productions_size.zero?
                        quantity * productions_count / productions_size
                      else # per campaign
                        next if productions_size.zero?
                        quantity / productions_size
                      end
      r << harvest_yield.in(item_unit).convert(yield_unit)
    end
    return nil if r.empty?
    r.sum
  end
end
