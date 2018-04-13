# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  accounted_at              :datetime
#  allocation_account_id     :integer          not null
#  asset_account_id          :integer
#  ceded                     :boolean
#  ceded_on                  :date
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  current_amount            :decimal(19, 4)
#  custom_fields             :jsonb
#  depreciable_amount        :decimal(19, 4)   not null
#  depreciated_amount        :decimal(19, 4)   not null
#  depreciation_method       :string           not null
#  depreciation_percentage   :decimal(19, 4)
#  depreciation_period       :string
#  description               :text
#  expenses_account_id       :integer
#  id                        :integer          not null, primary key
#  journal_entry_id          :integer
#  journal_id                :integer          not null
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  number                    :string           not null
#  product_id                :integer
#  purchase_amount           :decimal(19, 4)
#  purchase_id               :integer
#  purchase_item_id          :integer
#  purchased_on              :date
#  sale_id                   :integer
#  sale_item_id              :integer
#  scrapped_journal_entry_id :integer
#  scrapped_on               :date
#  sold_journal_entry_id     :integer
#  sold_on                   :date
#  started_on                :date             not null
#  state                     :string
#  stopped_on                :date             not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

class FixedAsset < Ekylibre::Record::Base
  include Attachable
  include Customizable
  acts_as_numbered
  enumerize :depreciation_method, in: %i[simplified_linear linear regressive none], predicates: { prefix: true } # graduated
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
  validates :allocation_account, :currency, :depreciation_method, :journal, presence: true
  validates :current_amount, :depreciation_percentage, :purchase_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :depreciable_amount, :depreciated_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, :number, presence: true, length: { maximum: 500 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :state, length: { maximum: 500 }, allow_blank: true
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(fixed_asset) { fixed_asset.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]
  validates :name, uniqueness: true
  validates :depreciation_method, inclusion: { in: depreciation_method.values }
  validates :asset_account, :expenses_account, presence: true
  enumerize :depreciation_period, in: %i[monthly quarterly yearly], default: -> { Preference.get(:default_depreciation_period).value || Preference.set!(:default_depreciation_period, :yearly, :string) }

  scope :drafts, -> { where(state: %w[draft]) }

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
    event :sell do
      transition in_use: :sold
    end
    event :scrap do
      transition in_use: :scrapped
    end
  end

  before_validation(on: :create) do
    self.state = :draft
    self.currency ||= Preference[:currency]
  end

  before_validation(on: :create) do
    self.depreciated_amount ||= 0
  end

  before_validation do
    self.state ||= :draft
    self.depreciation_period ||= Preference.get(:default_depreciation_period)
    self.depreciation_period ||= Preference.set!(:default_depreciation_period, :yearly, :string)
    self.purchase_amount ||= depreciable_amount
    self.purchased_on ||= started_on
    if depreciation_method_linear?
      if stopped_on && started_on
        self.depreciation_percentage = 100.0 * 365.25 / duration
      end
    elsif depreciation_method_simplified_linear?
      self.depreciation_percentage = 20 if depreciation_percentage.blank? || depreciation_percentage <= 0
      months = 12 * (100.0 / depreciation_percentage.to_f)
      self.stopped_on = started_on >> months.floor
      self.stopped_on += (months - months.floor) * 30.0 - 1
    end

    # self.currency = self.journal.currency
    true
  end

  validate do
    if currency && journal
      errors.add(:journal, :invalid) if currency != journal.currency
    end
    if started_on
      if self.stopped_on
        unless self.stopped_on >= started_on
          errors.add(:stopped_on, :posterior, to: started_on.l)
        end
      end
    end
    true
  end

  before_create do
    @auto_depreciate = true
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

  def on_unclosed_periods?
    started_on > journal.closed_on
  end

  def status
    return :go if in_use?
    return :caution if draft?
    return :stop if scrapped? || sold?
  end

  def sell
    return false unless can_sell?
    update_column(:sold_on, Date.today) unless sold_on
    super
  end

  def scrap
    return false unless can_scrap?
    update_column(:scrapped_on, Date.today) unless scrapped_on
    super
  end

  def updateable?
    draft? || in_use?
  end

  def destroyable?
    draft?
  end

  def add_amount(amount)
    unless depreciations.any?(&:journal_entry)
      update(purchase_amount: purchase_amount + amount, depreciable_amount: depreciable_amount + amount)
    end
  end

  # This callback permits to add journal entry corresponding to the fixed asset when entering in use
  bookkeep do |b|
    label = tc(:bookkeep_in_use_assets, resource: self.class.model_name.human, number: number, name: name)
    waiting_asset_account = Account.find_or_import_from_nomenclature(:outstanding_assets)
    fixed_assets_suppliers_account = Account.find_or_import_from_nomenclature(:fixed_assets_suppliers)
    fixed_assets_values_account = Account.find_or_import_from_nomenclature(:fixed_assets_values)
    exceptionnal_depreciations_inputations_expenses_account = Account.find_or_import_from_nomenclature(:exceptionnal_depreciations_inputations_expenses)

    # fixed asset link to purchase item
    if purchase_items.any? && in_use?
      # puts "with purchase".inspect.red
      b.journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
        amount = []
        purchase_items.each do |p_item|
          # TODO: get entry item concerning
          jei = JournalEntryItem.where(resource_id: p_item.id, resource_type: p_item.class.name, account_id: waiting_asset_account.id).first
          next unless jei && jei.real_balance.nonzero?
          entry.add_credit(label, jei.account.id, jei.real_balance)
          amount << jei.real_balance
        end
        entry.add_debit(label, asset_account.id, amount.compact.sum, resource: self, as: :fixed_asset)
      end

    # fixed asset link to nothing
    elsif in_use?
      # puts "without purchase".inspect.green
      b.journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
        entry.add_credit(label, fixed_assets_suppliers_account.id, depreciable_amount)
        entry.add_debit(label, asset_account.id, depreciable_amount, resource: self, as: :fixed_asset)
      end

    # fixed asset sold or scrapped
    elsif (sold? && !sold_journal_entry) || (scrapped? && !scrapped_journal_entry)

      out_on = sold_on
      out_on ||= scrapped_on

      # get last depreciation for date out_on
      depreciation_out_on = current_depreciation(out_on)

      if depreciation_out_on

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

        scrapped_value = depreciation_out_on.depreciable_amount
        scrapped_unvalue = depreciation_out_on.depreciated_amount

        # fixed asset sold
        label = tc(:bookkeep_in_sold_assets, resource: self.class.model_name.human, number: number, name: name)
        b.journal_entry(journal, printed_on: sold_on, as: :sold, if: sold?) do |entry|
          entry.add_credit(label, asset_account.id, depreciable_amount, resource: self, as: :fixed_asset)
          entry.add_debit(label, fixed_assets_values_account.id, scrapped_value)
          entry.add_debit(label, allocation_account.id, scrapped_unvalue)
        end

        # fixed asset scrapped
        label_1 = tc(:bookkeep_exceptionnal_scrapped_assets, resource: self.class.model_name.human, number: number, name: name)
        label_2 = tc(:bookkeep_exit_assets, resource: self.class.model_name.human, number: number, name: name)

        b.journal_entry(journal, printed_on: scrapped_on, as: :scrapped, if: scrapped?) do |entry|
          entry.add_debit(label_1, exceptionnal_depreciations_inputations_expenses_account.id, scrapped_value)
          entry.add_credit(label_1, allocation_account.id, scrapped_value)
          entry.add_debit(label_2, allocation_account.id, scrapped_value)
          entry.add_credit(label_2, asset_account.id, scrapped_value, resource: self, as: :fixed_asset)
        end
      end
    end
  end

  # Depreciate active fixed assets
  def self.depreciate(options = {})
    filtered_date = options[:until]

    depreciations = if filtered_date
                      FixedAssetDepreciation.with_active_asset_up_to(filtered_date)
                    else
                      FixedAssetDepreciation.with_active_asset
                    end

    transaction do
      # trusting the bookkeep to take care of the accounting
      depreciations.find_each { |depreciation| depreciation.update_attribute(:accountable, true) }
    end

    depreciations.count
  end

  def depreciate!
    planned_depreciations.clear
    # Computes periods
    starts = [started_on, self.stopped_on + 1]
    starts += depreciations.pluck(:started_on)

    # FinancialYear.ensure_exists_at!(self.stopped_on)
    # FinancialYear.where(started_on: started_on..self.stopped_on).reorder(:started_on).each do |financial_year|
    # start = financial_year.started_on
    # starts << start if started_on <= start && start <= self.stopped_on
    # end

    first_day_of_month = ->(date) { date.day == 1 } # date.succ.day < date.day }
    new_months = (started_on...stopped_on).select(&first_day_of_month)

    case depreciation_period
    when /monthly/
      starts += new_months
    when /quarterly/
      new_trimesters = new_months.select { |date| date.month.multiple_of? 3 }
      starts += new_trimesters
    when /yearly/
      new_years = new_months.select { |date| date.month == 1 }
      starts += new_years
    end

    starts = starts.uniq.sort
    send("depreciate_with_#{depreciation_method}_method", starts)
    self
  end

  # Depreciate using linear method
  def depreciate_with_linear_method(starts)
    depreciable_days = duration.round(2)
    depreciable_amount = self.depreciable_amount
    depreciations.each do |depreciation|
      depreciable_days -= depreciation.duration.round(2)
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
        duration = depreciation.duration.round(2)
        depreciation.amount = [remaining_amount, currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
        remaining_amount -= depreciation.amount
      end
      # depreciation.financial_year = FinancialYear.at(depreciation.started_on)

      depreciation.position = position
      position += 1
      depreciation.save!
    end
  end

  # Depreciate using simplified linear method
  # Years have 12 months with 30 days
  def depreciate_with_simplified_linear_method(starts)
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
      end
      # depreciation.financial_year = FinancialYear.at(depreciation.started_on)

      depreciation.position = position
      position += 1
      depreciation.save!
    end
  end

  # Depreciate using regressive method
  def depreciate_with_regressive_method(starts)
    # TODO
  end

  # Depreciate using regressive method
  def depreciate_with_none_method(starts)
    # TODO
  end

  def depreciable?
    depreciations.none?
  end

  # return the current_depreciation at current date
  def current_depreciation(on = Date.today)
    # get active depreciation (state  = in use)
    asset_depreciation = depreciations.where('? BETWEEN started_on AND stopped_on', on).where(locked: false).reorder(:position).last
    # get last active depreciation (state = scrapped or sold)
    asset_depreciation ||= depreciations.where('journal_entry_id IS NOT NULL').reorder(:position).last
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
    if options[:mode] == :simplified_linear
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

    # cursor = started_on.to_date
    # if started_on == started_on.end_of_month or started_on.day >= 30
    #   days += 1
    #   cursor = started_on.end_of_month + 1
    # elsif started_on.month == stopped_on.month and started_on.year == stopped_on.year
    #   days += so - sa + 1
    #   cursor = stopped_on
    # elsif started_on != started_on.beginning_of_month
    #   days += 30 - sa + 1
    #   cursor = started_on.end_of_month + 1
    # end

    # while (cursor >> 1).beginning_of_month < stopped_on.beginning_of_month
    #   cursor = cursor >> 1
    #   days += 30
    # end
    # if cursor < stopped_on
    #   days += [30, (so - cursor.day + 1)].min
    # end
    elsif options[:mode] == :linear
      days = (stopped_on - started_on) + 1
    else
      raise "What ? #{options[:mode].inspect}"
    end
    days.to_f
  end
end
