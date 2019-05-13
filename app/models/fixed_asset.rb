# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# == Table: fixed_assets
#
#  accounted_at                    :datetime
#  allocation_account_id           :integer          not null
#  asset_account_id                :integer
#  ceded                           :boolean
#  ceded_on                        :date
#  created_at                      :datetime         not null
#  creator_id                      :integer
#  currency                        :string           not null
#  current_amount                  :decimal(19, 4)
#  custom_fields                   :jsonb
#  depreciable_amount              :decimal(19, 4)   not null
#  depreciated_amount              :decimal(19, 4)   not null
#  depreciation_fiscal_coefficient :decimal(, )
#  depreciation_method             :string           not null
#  depreciation_percentage         :decimal(19, 4)
#  depreciation_period             :string
#  description                     :text
#  expenses_account_id             :integer
#  id                              :integer          not null, primary key
#  journal_entry_id                :integer
#  journal_id                      :integer          not null
#  lock_version                    :integer          default(0), not null
#  name                            :string           not null
#  number                          :string           not null
#  product_id                      :integer
#  purchase_amount                 :decimal(19, 4)
#  purchase_id                     :integer
#  purchase_item_id                :integer
#  purchased_on                    :date
#  sale_id                         :integer
#  sale_item_id                    :integer
#  scrapped_journal_entry_id       :integer
#  scrapped_on                     :date
#  sold_journal_entry_id           :integer
#  sold_on                         :date
#  started_on                      :date             not null
#  state                           :string
#  stopped_on                      :date             not null
#  updated_at                      :datetime         not null
#  updater_id                      :integer
#

class FixedAsset < Ekylibre::Record::Base
  include Attachable
  include Customizable
  acts_as_numbered
  enumerize :depreciation_method, in: %i[linear regressive none], predicates: { prefix: true } # graduated
  refers_to :currency
  belongs_to :asset_account, class_name: 'Account'
  belongs_to :expenses_account, class_name: 'Account'
  belongs_to :allocation_account, class_name: 'Account'
  belongs_to :journal, class_name: 'Journal'
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :sold_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :scrapped_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :product
  has_many :purchase_items, inverse_of: :fixed_asset
  has_many :depreciations, -> { order(:position) }, class_name: 'FixedAssetDepreciation'
  has_many :parcel_items, through: :purchase_item
  has_many :delivery_products, through: :parcel_items, source: :product
  has_many :planned_depreciations, -> { order(:position).where('NOT locked OR accounted_at IS NULL') }, class_name: 'FixedAssetDepreciation', dependent: :destroy
  has_one :tool, class_name: 'Equipment'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :ceded, inclusion: { in: [true, false] }, allow_blank: true
  validates :ceded_on, :purchased_on, :scrapped_on, :sold_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :currency, :depreciation_method, :journal, presence: true
  validates :current_amount, :depreciation_percentage, :purchase_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :depreciable_amount, :depreciated_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :depreciation_fiscal_coefficient, numericality: true, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, :number, presence: true, length: { maximum: 500 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :state, length: { maximum: 500 }, allow_blank: true
  validates :stopped_on, timeliness: { on_or_after: ->(fixed_asset) { fixed_asset.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]
  validates :name, uniqueness: true
  validates :depreciation_method, inclusion: { in: depreciation_method.values }
  validates :asset_account, presence: true
  validates :currency, match: { with: :journal, to_invalidate: :journal }
  validates :depreciation_fiscal_coefficient, presence: true, if: -> { depreciation_method_regressive? }
  validates :stopped_on, :allocation_account, :expenses_account, presence: { unless: :depreciation_method_none? }
  validates :scrapped_on, financial_year_writeable: { if: :scrapped? }
  validates :sold_on, financial_year_writeable: { if: :sold? }

  enumerize :depreciation_period, in: %i[monthly quarterly yearly], default: -> { Preference.get(:default_depreciation_period).value || Preference.set!(:default_depreciation_period, :yearly, :string) }

  scope :drafts, -> { where(state: %w[draft]) }
  scope :used, -> { where(state: %w[in_use]) }
  scope :sold_or_scrapped, -> { where(state: %w[sold scrapped]) }
  scope :start_before, ->(date) { where('fixed_assets.started_on <= ?', date) }

  # [DEPRECATIONS[
  #  - purchase_id
  #  - purchase_item_id
  # ]DEPRECATIONS]

  state_machine :state, initial: :draft do
    state :draft
    state :in_use
    state :sold
    state :scrapped
    event :start_up do
      transition draft: :in_use, if: :on_unclosed_periods?
    end
    after_transition from: :draft, to: :in_use, do: :depreciate_imported_depreciations!

    event :sell do
      transition in_use: :sold
    end
    before_transition(to: :sold) { |fa| fa.sold_on ||= Date.today }
    after_transition(to: :sold) { |fa| fa.update_depreciation_out_on!(fa.sold_on) }

    event :scrap do
      transition in_use: :scrapped
    end
    before_transition(to: :scrapped) { |fa| fa.scrapped_on ||= Date.today }
    after_transition(to: :scrapped) { |fa| fa.update_depreciation_out_on!(fa.scrapped_on) }
  end

  after_initialize do
    next if persisted?

    @auto_depreciate = true

    self.currency ||= Preference[:currency]
    self.depreciated_amount ||= 0
    self.state ||= :draft
  end

  before_validation do
    self.depreciation_period ||= Preference.get(:default_depreciation_period)
    self.depreciation_period ||= Preference.set!(:default_depreciation_period, :yearly, :string)
    self.depreciation_percentage = 20 if depreciation_percentage.blank? || depreciation_percentage <= 0
    self.purchase_amount ||= depreciable_amount
    self.purchased_on ||= started_on

    if depreciation_method_linear?
      if started_on
        months = 12 * (100.0 / depreciation_percentage.to_f)
        self.stopped_on = started_on >> months.floor
        self.stopped_on += (months - months.floor) * 30.0 - 1
      end
    end
    if depreciation_method_regressive?
      self.depreciation_fiscal_coefficient ||= 1.75
      if started_on
        months = 12 * (100.0 / depreciation_percentage.to_f)
        self.stopped_on = started_on >> months.floor
        self.stopped_on += (months - months.floor) * 30.0 - 1
      end
    end

    true
  end

  validate do
    errors.add(:base, :no_financial_year) if FinancialYear.count == 0

    if started_on
      # Should not be valid if not during a FinancialYear AND it exists a previous FinancialYear either closed or opened
      errors.add(:started_on, :invalid_date) if FinancialYear.on(started_on).nil? && FinancialYear.with_state(:opened, :closed).stopped_before(started_on).count > 0

      errors.add(:started_on, :financial_year_exchange_on_this_period) if started_during_financial_year_exchange?
      if self.stopped_on && stopped_on < started_on
        errors.add(:stopped_on, :posterior, to: started_on.l)
      end
    end
    true
  end

  before_update do
    @auto_depreciate = false
    old = self.class.find(id)
    %i[depreciable_amount started_on stopped_on depreciation_method
       depreciation_period depreciation_percentage currency].each do |attr|
      @auto_depreciate = true if send(attr) != old.send(attr)
    end
  end

  after_save do
    # if purchase_item
    # Link products to fixed asset
    # delivery_products.each do |product|
    # product.fixed_asset = self
    # unless product.save
    #  Rails.logger.warn('Cannot link fixed_asset to its products automatically')
    # end
    # end
    # end
    depreciate! if @auto_depreciate
  end

  def depreciate_imported_depreciations!
    depreciations.up_to(FinancialYear.opened.first.started_on).map { |fad| fad.update(accountable: true) }
  end

  def on_unclosed_periods?
    started_on > journal.closed_on
  end

  def status
    return :go if in_use?
    return :caution if draft?
    return :stop if scrapped? || sold?
  end

  def update_depreciation_out_on!(out_on)
    depreciation_out_on = current_depreciation(out_on)
    return false if depreciation_out_on.nil?

    # check if depreciation have journal_entry
    if depreciation_out_on.journal_entry
      raise StandardError, "This fixed asset depreciation is already bookkeep ( Entry : #{depreciation_out_on.journal_entry.number})"
    end

    next_depreciations = depreciations.where('position > ?', depreciation_out_on.position)

    # check if next depreciations have journal_entry
    if next_depreciations.any?(&:journal_entry)
      raise StandardError, "The next fixed assets depreciations are already bookkeep ( Entry : #{d.journal_entry.number})"
    end

    # stop bookkeeping next depreciations
    next_depreciations.update_all(accountable: false, locked: true)

    # use amount to last bookkeep (net_book_value == current_depreciation.depreciable_amount)
    # use amount to last bookkeep (already_depreciated_value == current_depreciation.depreciated_amount)

    # compute part time

    first_period = out_on.day
    global_period = (depreciation_out_on.stopped_on - depreciation_out_on.started_on) + 1
    first_ratio = (first_period.to_f / global_period.to_f) if global_period
    # second_ratio = (1 - first_ratio)

    first_depreciation_amount_ratio = (depreciation_out_on.amount * first_ratio).round(2)
    # second_depreciation_amount_ratio = (depreciation_out_on.amount * second_ratio).round(2)

    # update current_depreciation with new value and bookkeep it
    depreciation_out_on.stopped_on = out_on
    depreciation_out_on.amount = first_depreciation_amount_ratio
    depreciation_out_on.accountable = true
    depreciation_out_on.save!

  end

  def updateable?
    draft? || in_use?
  end

  def destroyable?
    draft?
  end

  def add_amount(amount)
    unless depreciations.any?(&:journal_entry)
      update!(purchase_amount: purchase_amount + amount, depreciable_amount: depreciable_amount + amount)
    end
  end

  def update_amounts
    unless depreciations.any?(&:journal_entry)
      amount = purchase_items.map(&:pretax_amount).sum
      update(purchase_amount: amount, depreciable_amount: amount)
    end
  end

  def started_during_financial_year_exchange?
    FinancialYearExchange.opened.where('? BETWEEN started_on AND stopped_on', started_on).any?
  end

  def opened_financial_year?
    FinancialYear.on(started_on)&.opened?
  end

  def started_during_financial_year_closure_preparation?
    FinancialYear.on(started_on)&.closure_in_preparation?
  end

  # This callback permits to add journal entry corresponding to the fixed asset when entering in use
  bookkeep

  # Depreciate active fixed assets
  def self.depreciate(options = {})
    depreciations = FixedAssetDepreciation.with_active_asset
    depreciations = depreciations.up_to(options[:until]) if options[:until]
    transaction do
      # trusting the bookkeep to take care of the accounting
      depreciations.find_each do |dep|
        dep.update!(accountable: true)
      end
      return depreciations.count
    end
    0
  end

  def depreciate!
    planned_depreciations.clear

    # Computes periods
    unless depreciation_method_none?
      fy_reference = FinancialYear.at(started_on) || FinancialYear.opened.first

      periods = DepreciationCalculator.new(fy_reference, depreciation_period.to_sym).depreciation_period(started_on, depreciation_percentage)

      starts = periods.map(&:first) << (periods.last.second + 1.day)

      send("depreciate_with_#{depreciation_method}_method", starts)
    end

    self
  end

  # Depreciate using linear method
  # Years have 12 months with 30 days
  def depreciate_with_linear_method(starts)
    first_fy = FinancialYear.opened.first

    depreciable_days = duration
    depreciable_amount = self.depreciable_amount
    reload.depreciations.each do |depreciation|
      depreciable_days -= depreciation.duration
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    starts.each_with_index do |start, index|
      next if starts[index + 1].nil?
      depreciation = depreciations.find_by(started_on: start)
      unless depreciation
        depreciation = depreciations.new(started_on: start, stopped_on: starts[index + 1] - 1)
        duration = depreciation.duration
        depreciation.amount = [remaining_amount, currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
        remaining_amount -= depreciation.amount

        depreciation.locked = depreciation.started_on < first_fy.started_on
      end
      # depreciation.financial_year = FinancialYear.at(depreciation.started_on)

      depreciation.position = position
      position += 1
      depreciation.save!
    end
  end

  # Depreciate using regressive method
  def depreciate_with_regressive_method(starts)
    first_fy = FinancialYear.opened.first

    depreciable_days = duration
    depreciable_amount = self.depreciable_amount
    reload.depreciations.each do |depreciation|
      depreciable_days -= depreciation.duration
      depreciable_amount -= depreciation.amount
    end

    remaining_days = depreciable_days
    regressive_depreciation_percentage = depreciation_percentage * depreciation_fiscal_coefficient

    ## Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1

    starts.each_with_index do |start, index|
      next if starts[index + 1].nil? || remaining_amount <= 0
      depreciation = depreciations.find_by(started_on: start)
      unless depreciation
        depreciation = depreciations.new(started_on: start, stopped_on: starts[index + 1] - 1)
        duration = depreciation.duration

        current_year = index
        if depreciation_period == :quarterly
          current_year /= 4
        elsif depreciation_period == :monthly
          current_year /= 12
        end

        remaining_linear_depreciation_percentage = (100 * depreciation_percentage / (100 - (current_year * depreciation_percentage))).round(2)
        percentage = [regressive_depreciation_percentage, remaining_linear_depreciation_percentage].max

        depreciation.amount = currency.to_currency.round(remaining_amount * (percentage / 100) * (duration / 360))
        remaining_amount -= depreciation.amount

        depreciation.locked = depreciation.started_on < first_fy.started_on
      end
      next if depreciation.amount.to_f == 0.0

      depreciation.position = position
      position += 1
      depreciation.save!
      remaining_days -= duration
    end
  end

  def depreciable?
    depreciations.none?
  end

  # return the current_depreciation at current date
  def current_depreciation(on = Date.today)
    # get active depreciation
    asset_depreciation = depreciations.where('? BETWEEN started_on AND stopped_on', on).reorder(:position).last
    # get last active depreciation
    asset_depreciation ||= depreciations.reorder(:position).last
    return nil unless asset_depreciation
    asset_depreciation
  end

  # return the net book value at current date
  def net_book_value(on = Date.today)
    return nil unless current_depreciation(on)
    current_depreciation(on).depreciable_amount
  end

  # return the global amount already depreciated
  def already_depreciated_value(on = Date.today)
    return nil unless current_depreciation(on)
    current_depreciation(on).depreciated_amount
  end

  # Returns the duration in days of all the depreciations
  def duration
    self.class.duration(started_on, self.stopped_on, mode: depreciation_method.to_sym)
  end

  # Returns the duration in days between to 2 times
  def self.duration(started_on, stopped_on, options = {})
    days = 0
    options[:mode] ||= :linear
    if options[:mode] == :linear
      sa = (started_on.day >= 30 || (started_on.end_of_month == started_on) ? 30 : started_on.day)
      so = (stopped_on.day >= 30 || (stopped_on.end_of_month == stopped_on) ? 30 : stopped_on.day)

      if started_on.beginning_of_month == stopped_on.beginning_of_month
        days = so - sa + 1
      else
        days = 30 - sa + 1
        cursor = started_on.beginning_of_month
        while (cursor >> 1) < stopped_on.beginning_of_month
          cursor = cursor >> 1
          days += 30
        end
        days += so
      end
    elsif options[:mode] == :regressive
      sa = (started_on.day >= 30 || (started_on.end_of_month == started_on) ? 30 : 1)
      so = (stopped_on.day >= 30 || (stopped_on.end_of_month == stopped_on) ? 30 : stopped_on.day)

      if started_on.beginning_of_month == stopped_on.beginning_of_month
        days = so - sa + 1
      else
        days = 30 - sa + 1
        cursor = started_on.beginning_of_month
        while (cursor >> 1) < stopped_on.beginning_of_month
          cursor = cursor >> 1
          days += 30
        end
        days += so
      end
    else
      raise "What ? #{options[:mode].inspect}"
    end
    days.to_f
  end
end
