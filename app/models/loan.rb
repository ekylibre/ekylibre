# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: loans
#
#  accountable_repayments_started_on :date
#  accounted_at                      :datetime
#  activity_id                       :integer(4)
#  amount                            :decimal(19, 4)   not null
#  bank_guarantee_account_id         :integer(4)
#  bank_guarantee_amount             :integer(4)
#  cash_id                           :integer(4)       not null
#  created_at                        :datetime         not null
#  creator_id                        :integer(4)
#  currency                          :string           not null
#  custom_fields                     :jsonb
#  id                                :integer(4)       not null, primary key
#  initial_releasing_amount          :boolean          default(TRUE), not null
#  insurance_account_id              :integer(4)
#  insurance_percentage              :decimal(19, 4)   not null
#  insurance_repayment_method        :string
#  interest_account_id               :integer(4)
#  interest_percentage               :decimal(19, 4)   not null
#  journal_entry_id                  :integer(4)
#  lender_id                         :integer(4)       not null
#  loan_account_id                   :integer(4)
#  lock_version                      :integer(4)       default(0), not null
#  name                              :string           not null
#  ongoing_at                        :datetime
#  provider                          :jsonb
#  repaid_at                         :datetime
#  repayment_duration                :integer(4)       not null
#  repayment_method                  :string           not null
#  repayment_period                  :string           not null
#  shift_duration                    :integer(4)       default(0), not null
#  shift_method                      :string
#  started_on                        :date             not null
#  state                             :string
#  updated_at                        :datetime         not null
#  updater_id                        :integer(4)
#  use_bank_guarantee                :boolean
#

class Loan < ApplicationRecord
  include Attachable
  include Customizable
  include Transitionable
  include Providable
  # take care to restart serveur when updating code because of Transitionable lib
  enumerize :repayment_method, in: %i[constant_rate constant_amount], default: :constant_amount
  enumerize :shift_method, in: %i[immediate_payment anatocism], default: :immediate_payment
  enumerize :repayment_period, in: %i[month year trimester semester], default: :month, predicates: { prefix: true }
  enumerize :insurance_repayment_method, in: %i[initial to_repay], default: :to_repay, predicates: true
  enumerize :state, in: %i[draft ongoing repaid], predicates: true, default: :draft, i18n_scope: "models.#{model_name.param_key}.states"
  refers_to :currency
  belongs_to :activity
  belongs_to :cash
  belongs_to :journal_entry
  belongs_to :lender, class_name: 'Entity'
  belongs_to :third, foreign_key: :lender_id, class_name: 'Entity' # alias for lender
  belongs_to :loan_account,         class_name: 'Account'
  belongs_to :interest_account,     class_name: 'Account'
  belongs_to :insurance_account, class_name: 'Account'
  belongs_to :bank_guarantee_account, class_name: 'Account'
  has_many :repayments, -> { order(:position) }, class_name: 'LoanRepayment', dependent: :destroy, counter_cache: false
  has_one :journal, through: :cash
  has_many :economic_cash_indicators, class_name: 'EconomicCashIndicator', inverse_of: :loan, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accountable_repayments_started_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years }, type: :date }, allow_blank: true
  validates :accounted_at, :ongoing_at, :repaid_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :amount, :insurance_percentage, :interest_percentage, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :bank_guarantee_amount, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :cash, :currency, :lender, :repayment_method, :repayment_period, :third, presence: true
  validates :initial_releasing_amount, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 500 }
  validates :repayment_duration, :shift_duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :use_bank_guarantee, inclusion: { in: [true, false] }, allow_blank: true
  # ]VALIDATORS]
  validates :loan_account, :interest_account, presence: true
  validates :insurance_account, presence: { if: -> { updateable? && insurance_percentage.present? && insurance_percentage.nonzero? } }
  validates :amount, numericality: { greater_than: 0 }
  validates :currency, match: { with: :cash }
  validates :started_on, ongoing_exchanges: true

  scope :drafts, -> { where(state: %w[draft]) }
  scope :ongoing_within, ->(start_time, stop_time) { where('loans.ongoing_at BETWEEN ? and ?', start_time, stop_time) }

  after_initialize do
    next if persisted?

    self.currency ||= Preference[:currency]
    self.state ||= :draft
  end

  before_validation do
    self.state ||= :draft
    self.ongoing_at ||= started_on.to_time if started_on
    self.currency ||= cash.currency if cash
    self.shift_duration ||= 0
    true
  end

  after_save do
    generate_repayments if (draft? || ongoing?)
    # if accountable_repayments_started_on, locked repayments before accountable_repayments_started_on
    if accountable_repayments_started_on
      r = repayments.where('due_on < ?', accountable_repayments_started_on)
      r.update_all(locked: true)
    end
    # update economic_cash_indicators
    update_economic_cash_indicators
  end

  # Prevents from deleting if entry exist
  protect on: :destroy do
    (journal_entry && !journal_entry.destroyable?) || repayments.any? { |repayment| !repayment.destroyable? } || repaid?
  end

  # Prevents from deleting if entry exist
  protect on: :update do
    !repayments.all?(&:updateable?) || (journal_entry && !journal_entry.editable?)
  end

  # compute and save loan for each cash movement in economic_cash_indicators
  def update_economic_cash_indicators
    self.economic_cash_indicators.destroy_all

    # build default attributes
    default_attributes = { context: 'Emprunt',
                           context_color: 'Maroon',
                           origin: 'loan',
                           nature: nil }

    # received cash from loan
    campaign = Campaign.of(ongoing_at.year)
    loan_attrs = { campaign_id: campaign.id,
                   direction: 'revenue',
                   used_on: ongoing_at.to_date,
                   paid_on: ongoing_at.to_date,
                   amount: amount,
                   pretax_amount: amount }
    self.economic_cash_indicators.create!(default_attributes.merge(loan_attrs))

    # create cash movement for each repayments
    repayments.each do |rep|
      campaign = Campaign.of(rep.due_on.year)
      rep_attributes = { campaign_id: campaign.id,
                         direction: 'expense',
                         used_on: rep.due_on,
                         paid_on: rep.due_on,
                         amount: rep.amount,
                         pretax_amount: rep.amount }
      attrs = default_attributes.merge(rep_attributes)
      self.economic_cash_indicators.create!(attrs)
    end
  end

  bookkeep do |b|
    # when money arrive (ongoing_at)
    # when first payment started (started_on)

    existing_financial_year = FinancialYear.at(ongoing_at)

    b.journal_entry(journal, printed_on: ongoing_at.to_date, if: (initial_releasing_amount && ongoing_at? && ongoing_at <= Time.zone.now && existing_financial_year)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, name: name)

      entry.add_debit(label, cash.account_id, amount, as: :bank)
      entry.add_credit(label, loan_account_id, amount, as: :loan)

      if use_bank_guarantee?
        label_guarantee = tc(:bookkeep_guarantee_payment, resource: self.class.model_name.human, name: name)
        entry.add_debit(label_guarantee, bank_guarantee_account_id, bank_guarantee_amount, as: :bank_guarantee)
        entry.add_credit(label_guarantee, cash.account_id, bank_guarantee_amount, as: :bank)
      end
    end

    true
  end

  # Bookkeep all repayments until today of given date which must anterior to
  # today. :id parameter permit to filter on wanted loans.
  def self.bookkeep_repayments(options = {})
    limit_on = Time.zone.today
    limit_on = [options[:until], limit_on].min if options[:until]
    repayments = LoanRepayment.bookkeepable_before(limit_on)
    count = repayments.count
    repayments.find_each { |repayment| repayment.update(accountable: true) }
    count
  end

  def generate_repayments
    period = if repayment_period_month?
               12
             elsif repayment_period_trimester?
               4
             elsif repayment_period_semester?
               2
             else
               1
             end

    length = if repayment_period_month?
               1.month
             elsif repayment_period_trimester?
               3.months
             elsif repayment_period_semester?
               6.months
             else
               1.year
             end

    ids = []
    Calculus::Loan
      .new(
        amount,
        repayment_duration,
        interests:  { interest_amount:  interest_percentage  / 100.0 },
        insurances: { insurance_amount: insurance_percentage / 100.0 },
        period: period,
        length: length,
        shift: self.shift_duration,
        shift_method: shift_method.to_sym,
        insurance_method: insurance_repayment_method,
        started_on: started_on
      )
      .compute_repayments(repayment_method)
      .each do |repayment|
        if r = repayments.find_by(position: repayment[:position])
          r.update_attributes!(repayment)
        else
          r = repayments.create!(repayment)
        end
        ids << r.id
      end
    repayments.destroy(repayments.where.not(id: ids))
    reload
  end

  # return Decimal
  def current_remaining_amount(on = Date.today)
    r = repayments.where('due_on <= ?', on).reorder(:position).last
    return 0.0 unless r

    r.remaining_amount
  end

  def status
    return :go if ongoing?
    return :caution if draft?
    return :stop if repaid?
  end

  def human_status
    I18n.t("tooltips.models.loan.#{status}")
  end

  def number
    "L#{id.to_s}_#{started_on.to_s}"
  end

  def editable?
    updateable?
  end
end
