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
class ActivityBudget < ApplicationRecord
  belongs_to :activity
  belongs_to :campaign
  belongs_to :technical_itinerary
  with_options class_name: 'ActivityBudgetItem', inverse_of: :activity_budget do
    has_many :items, dependent: :destroy
    has_many :expenses, -> { expenses }
    has_many :revenues, -> { revenues }
  end
  has_many :journal_entry_items, dependent: :nullify
  has_many :purchase_items, dependent: :nullify
  has_many :sale_items, dependent: :nullify

  enumerize :nature, in: %i[manual compute_from_itk], default: :manual, predicates: true

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
  delegate :count, to: :productions, prefix: true

  before_validation on: :create do
    self.currency ||= Preference[:currency]
  end

  def expenses_amount
    expenses.sum(:amount)
  end

  def revenues_amount
    revenues.sum(:amount)
  end

  def all_main_activities_gross_margin
    main_activities_budgets_on_campaign = ActivityBudget.joins(:activity).where(campaign: campaign, activities: { nature: :main })
    global_revenus_on_main_activity = main_activities_budgets_on_campaign.map(&:revenues_amount).compact.sum
    global_expenses_on_main_activity = main_activities_budgets_on_campaign.map(&:expenses_amount).compact.sum
    all_main_activities_gross_margin = global_revenus_on_main_activity - global_expenses_on_main_activity
  end

  # compute gross margin repartition for indirect expense
  def gross_margin_ratio
    activity_gross_margin = revenues_amount - expenses_amount
    ratio = activity_gross_margin / all_main_activities_gross_margin
  end

  # Compute indirect expenses coming from auxiliary activities (including all
  # loan repayments).
  def indirect_expenses
    main_activities_budgets_on_campaign = ActivityBudget.joins(:activity).where(campaign: campaign, activities: { nature: :main })
    main_budgets_count = main_activities_budgets_on_campaign.count
    @indirect_expenses ||= ActivityBudget.joins(:activity).where(campaign: campaign, activities: { nature: :auxiliary }).each_with_object({}) do |b, h|
      ratio = 0.0
      if b.activity.distribution_key == :gross_margin
        ratio = gross_margin_ratio
        # puts gross_margin_ratio.to_f.inspect.yellow

      elsif b.activity.distribution_key == :percentage
        # compute ratio with opened activities
        # FIXME: All distributions can refer to non-opened activies for current campaign
        part = b.distributions.where(main_activity_id: activity_id).sum(:affectation_percentage) || 0.0
        total = b.distributions.sum(:affectation_percentage) || 0.0
        ratio = total.zero? ? 0.0 : (part / total)
      elsif b.activity.distribution_key == :activity
        ratio = 1.0 / main_budgets_count
      end
      h[b] = ratio
      # puts h.inspect.red
    end
  end

  def indirect_expenses_amount
    @indirect_expenses_amount ||= indirect_expenses.sum do |b, ratio|
      (b.expenses_amount + b.loan_repayments_amount - b.revenues_amount) * ratio
    end
  end

  def real_indirect_expenses_amount
    @real_indirect_expenses_amount ||= indirect_expenses.sum do |b, ratio|
      (b.real_expenses_amount + b.real_loan_repayments_amount - b.real_revenues_amount) * ratio
    end
  end

  # Compute real expenses amount on purchase invoices only
  def real_expenses_amount
    # compute from intervention
    if activity.interventions.any?
      activity.decorate.production_costs(campaign)[:global_costs][:total]
    # compute from purchases
    else
      @real_expenses_amount ||= PurchaseItem.joins(:purchase).where(
        activity_budget: self,
        purchases: { type: 'PurchaseInvoice' }
      ).sum(:amount)
    end
  end

  def real_loan_repayments_amount
    loan_repayments_amount(on: Date.today)
  end

  def real_revenues_amount
    SaleItem.joins(:sale).where(
      activity_budget: self
    ).sum(:amount)
  end

  def loan_repayments(options = {})
    repayments = LoanRepayment.includes(:loan).where(loans: { activity_id: self.activity_id }, due_on: Date.civil(campaign.harvest_year, 1, 1)..Date.civil(campaign.harvest_year, 12, 31))
    repayments = repayments.where('due_on <= ?', options[:on]) if options.key?(:on)
    repayments
  end

  def loan_repayments_amount(options = {})
    loan_repayments(options).sum(:amount)
  end

  def loan_repayments_charges_amount(options = {})
    loan_repayments(options).sum(:interest_amount) + loan_repayments(options).sum(:insurance_amount)
  end

  def name
    tc(:name, activity_name: activity_name, campaign_name: campaign_name)
  end

  def currency_precision
    Onoma::Currency.find(currency).precision
  end

  def productions
    return ActivityProduction.none if activity.nil?

    activity.productions.of_campaign(campaign)
  end

  def any_production?
    productions.any?
  end

  # check production size if 'manual' or area in scenario if 'compute_from_itk'
  def productions_size
    if manual?
      productions.map(&:size_value).sum
    elsif compute_from_itk? && technical_itinerary
      # TODO: grab area from sap / sa / s with ti, campaign and activity
      s_ids = Scenario.where(campaign_id: campaign.id).pluck(:id)
      sa_ids = ScenarioActivity.where(activity_id: activity.id, planning_scenario_id: s_ids).pluck(:id)
      sap = ScenarioActivity::Plot.where(technical_itinerary_id: technical_itinerary.id, planning_scenario_activity_id: sa_ids)
      sap.sum(:area).round(2)
    end
  end

  def productions_count
    if manual?
      productions.map(&:size_value).sum
    elsif compute_from_itk?
      # TODO: grab plot count from sap / sa / s with ti, campaign and activity
      s_ids = Scenario.where(campaign_id: campaign.id).pluck(:id)
      sa_ids = ScenarioActivity.where(activity_id: activity.id, planning_scenario_id: s_ids).pluck(:id)
      sap = ScenarioActivity::Plot.where(technical_itinerary_id: technical_itinerary.id, planning_scenario_activity_id: sa_ids)
      sap.count
    end
  end

  def estimated_duration
    result = []
    workers_v_ids = ProductNatureVariant.where(variety: "worker").pluck(:id)
    time_actors = items.where(direction: :expense, variant_indicator: "working_duration", variant_id: workers_v_ids)
    time_actors.each do |a|
      if a.per_working_unit?
        next if productions_size.zero?

        result << a.quantity * productions_size
      elsif a.per_production?
        next if productions_count.zero?

        result << a.quantity * productions_count
      else
        result << a.quantity
      end
    end
    return result.compact.sum
  end

  def current_market_price
    start = Date.parse("#{campaign.harvest_year}-01-01")
    stop = Date.parse("#{campaign.harvest_year}-12-31")
    eu_dataset = RegisteredEuMarketPrice.of_variety(activity.cultivation_variety).of_country('FR').between(start, stop).reorder(:start_date)
    if eu_dataset.any?
      eu_dataset.last.price
    else
      nil
    end
  end

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
    yield_unit = Onoma::Unit.find(options[:unit] || :quintal_per_hectare)
    unless yield_unit
      raise ArgumentError.new("Cannot find unit for yield estimate: #{options[:unit].inspect}")
    end

    Onoma::Variety.find!(variety)

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
      item_unit = Onoma::Unit.find("#{quantity_unit}_per_#{activity.size_unit.name}")
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
