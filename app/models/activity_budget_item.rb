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
# == Table: activity_budget_items
#
#  activity_budget_id :integer          not null
#  amount             :decimal(19, 4)   default(0.0)
#  computation_method :string           not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string           not null
#  direction          :string           not null
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  quantity           :decimal(19, 4)   default(0.0)
#  unit_amount        :decimal(19, 4)   default(0.0)
#  unit_currency      :string           not null
#  unit_population    :decimal(19, 4)
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer
#  variant_indicator  :string
#  variant_unit       :string
#

class ActivityBudgetItem < ApplicationRecord
  refers_to :currency
  enumerize :direction, in: %i[revenue expense], predicates: true
  enumerize :frequency, in: %i[per_day per_month per_year], predicates: true, default: :per_year, i18n_scope: "labels"
  enumerize :origin, in: %i[manual itk automatic], predicates: true, default: :manual
  enumerize :nature, in: %i[static dynamic], predicates: true, default: :static
  enumerize :computation_method, in: %i[per_campaign per_production per_working_unit], default: :per_working_unit, predicates: true
  # refers_to :variant_indicator, class_name: 'Indicator' # in: Activity.support_variant_indicator.values
  # refers_to :variant_unit, class_name: 'Unit'

  belongs_to :activity_budget, inverse_of: :items
  belongs_to :transfered_activity_budget, class_name: 'ActivityBudget'
  belongs_to :unit, inverse_of: :budget_items
  has_one :activity, through: :activity_budget
  has_one :campaign, through: :activity_budget
  belongs_to :variant, class_name: 'ProductNatureVariant'
  belongs_to :tax
  has_many :productions, through: :activity
  belongs_to :product_parameter, class_name: 'InterventionTemplate::ProductParameter', inverse_of: :budget_items
  has_many :economic_cash_indicators, class_name: 'EconomicCashIndicator', inverse_of: :activity_budget_item, dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :amount, :global_amount, :quantity, :unit_amount, :unit_population, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :activity_budget, :computation_method, :currency, :direction, :frequency, presence: true
  validates :locked, :use_transfer_price, inclusion: { in: [true, false] }, allow_blank: true
  validates :main_output, inclusion: { in: [true, false] }
  validates :paid_on, :used_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  validates :repetition, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :transfer_price, numericality: true, allow_blank: true
  validates :unit_currency, presence: true, length: { maximum: 500 }
  validates :variant_indicator, :variant_unit, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :variant, presence: true
  validates :unit_amount, presence: { message: :invalid }
  validates :currency, match: { with: :activity_budget }

  delegate :size_indicator, :size_unit, to: :activity
  delegate :currency, to: :activity_budget, prefix: true
  delegate :name, to: :variant, prefix: true

  scope :revenues, -> { where(direction: :revenue).includes(:variant) }
  scope :expenses, -> { where(direction: :expense).includes(:variant) }
  scope :of_campaign, ->(campaign) { joins(:activity_budget).merge(ActivityBudget.of_campaign(campaign)) }
  scope :of_activity, ->(activity) { joins(:activity_budget).merge(ActivityBudget.of_activity(activity)) }
  scope :of_main_output, -> { where(main_output: true) }

  before_validation do
    self.unit_currency = Preference[:currency] if unit_currency.blank?
    self.currency = unit_currency if currency.blank?
    self.origin ||= :manual
    self.nature ||= :static
    self.frequency ||= :per_year
    self.repetition ||= 1
    self.tax ||= Tax.usable_in_budget.find_by(amount: 0.0)
  end

  validate do
    # ???: Why do we even have both if we check that they're always equals??
    if currency && unit_currency
      errors.add(:currency, :invalid) if currency != unit_currency
    end
    true
  end

  after_validation do
    self.pretax_amount = unit_amount * quantity * coefficient if unit_amount.present?
    self.global_pretax_amount = self.pretax_amount * year_repetition if self.pretax_amount.present?
    self.amount = tax.amount_of(self.pretax_amount) if self.pretax_amount.present? && tax.present?
    self.global_amount = self.amount * year_repetition if self.amount.present?
  end

  after_save :handle_transfered_item
  after_save :update_economic_cash_indicators

  # Create or update expense in the activity budget in witch item is transfered
  def handle_transfered_item
    return if !use_transfer_price
    return if (transfered_activity_budget = ActivityBudget.find_by_id(transfered_activity_budget_id)).nil?

    attributes = {
      quantity: total_quantity,
      used_on: used_on,
      unit_id: unit_id,
      unit_amount: transfer_price,
      tax: tax,
      computation_method: :per_campaign,
      locked: true
    }
    if (expense = transfered_activity_budget.expenses.find_by(variant: variant))
      expense.update!(attributes)
    else
      transfered_activity_budget.items.create!(
        attributes.merge({ direction: :expense, variant: variant })
      )
    end
  end

  # Computes the coefficient to use for amount computation
  def coefficient
    return 0 unless activity_budget
    if per_production?
      return activity_budget.productions_count || 0
    elsif per_working_unit?
      return activity_budget.productions_size || 0
    end

    1
  end

  # return the repetition of the item for the budget
  def year_repetition
    if per_year?
      repetition
    elsif per_month?
      repetition * 12
    elsif per_day?
      repetition * 365
    else
      1
    end
  end

  # return the number of day between repetition
  def day_gap
    if year_repetition != 0
      365 / year_repetition
    else
      365
    end
  end

  # compute and save activity_budget_item for each cash movement in economic_cash_indicators
  def update_economic_cash_indicators
    self.economic_cash_indicators.destroy_all
    # build default attributes
    default_attributes = { context: self.activity_budget.name,
                           context_color: self.activity.color,
                           campaign: self.campaign,
                           activity: self.activity,
                           activity_budget: self.activity_budget,
                           product_nature_variant: self.variant,
                           pretax_amount: self.pretax_amount,
                           amount: self.amount,
                           direction: self.direction,
                           origin: self.origin,
                           nature: self.nature }
    gap_used_on = self.used_on
    gap_paid_on = self.paid_on
    # create cash movement for each year repetition with used and paid
    year_repetition.times do |_rep|
      economic_cash_indicators.create!(default_attributes.merge({ used_on: gap_used_on, paid_on: gap_paid_on }))
      gap_used_on += day_gap.days if gap_used_on
      gap_paid_on += day_gap.days if gap_paid_on
    end
  end

  # Duplicate an item in the same budget by default. Each attribute are
  # overwritable.
  def duplicate!(updates = {})
    new_attributes = %i[
      activity_budget amount pretax_amount computation_method currency direction
      nature origin frequency repetition used_on main_output
      quantity unit_amount unit_currency unit_population variant
      variant_indicator variant_unit unit_id tax_id
    ].each_with_object({}) do |attr, h|
      h[attr] = send(attr)
      h
    end.merge(updates)
    self.class.create!(new_attributes)
  end

  def total_quantity
    quantity * coefficient
  end

  def direct_expenses_amount
    activity_budget.expenses_amount * expenses_distribution_key
  end

  def loan_repayments_amount
    activity_budget.loan_repayments_amount * expenses_distribution_key
  end

  def indirect_expenses_amount
    activity_budget.indirect_expenses_amount * expenses_distribution_key
  end

  # Direct and indirect expenses amount
  def total_expenses_amount
    a = activity_budget.expenses_amount + activity_budget.loan_repayments_amount
    a += activity_budget.indirect_expenses_amount if activity.main?
    a * expenses_distribution_key
  end

  def expenses_distribution_key
    @expenses_distribution_key ||= amount / activity_budget.revenues.sum(:amount)
  end

  # Computes with direct expenses and indirect expenses for main activities
  # No commercialization_threshold for auxiliary activities
  def commercialization_threshold
    total_expenses_amount
  end

  def raw_margin
    amount - direct_expenses_amount - loan_repayments_amount
  end

  # Cmpute net margin
  def net_margin
    return nil if activity.auxiliary?

    amount - total_expenses_amount
  end

  # Computes real quantity based on intervention outputs
  # Same grandeur as quantity
  def real_quantity
    unless @real_quantity
      # Get quantities from intervention outputs
      population = InterventionOutput.where(
        variant: self.variant,
        group_id: InterventionTarget.where(
          product_id: activity.productions.of_campaign(campaign).select(:support_id)
        ).select(:group_id)
      ).sum(:quantity_population)
      # Convert to unit of item
      if self.variant_indicator && population
        @real_quantity = (self.variant.get(self.variant_indicator) * population).in(variant_unit).to_d
      else
        @real_quantity = 0
      end
      if per_working_unit? && activity_budget.productions_size != 0
        @real_quantity /= activity_budget.productions_size
      elsif per_production? && activity_budget.productions_count != 0
        @real_quantity /= activity_budget.productions_count
      end
    end
    @real_quantity
  end

  def real_total_expenses_amount
    real_direct_expenses_amount + real_loan_repayments_amount + real_indirect_expenses_amount
  end

  def real_direct_expenses_amount
    # TODO: Add computation
    rdea = 5555
    # Without harvest, only zero.....
    rdea * real_expenses_distribution_key
  end

  def real_loan_repayments_amount
    activity_budget.loan_repayments_amount(on: Date.today) * real_expenses_distribution_key
  end

  def real_indirect_expenses_amount
    activity_budget.real_indirect_expenses_amount * real_expenses_distribution_key
  end

  def real_expenses_distribution_key
    unless @real_expenses_distribution_key
      total = activity_budget.revenues.map(&:real_amount).sum
      if total.zero?
        @real_expenses_distribution_key = 0
      else
        @real_expenses_distribution_key = real_amount / activity_budget.revenues.map(&:real_amount).sum
      end
    end
    @real_expenses_distribution_key
  end

  def real_total_quantity
    real_quantity * coefficient
  end

  def real_unit_amount
    # What to take? CUMP, budget, last sale, total_weighted_average
    unit_amount
  end

  def real_amount
    real_unit_amount * real_quantity * coefficient
  end

  def real_raw_margin
    real_amount - real_direct_expenses_amount - real_loan_repayments_amount
  end

  def real_commercialization_threshold
    real_total_expenses_amount
  end

  def real_net_margin
    return nil if activity.auxiliary?

    real_amount - real_total_expenses_amount
  end
end
