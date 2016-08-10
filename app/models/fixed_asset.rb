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
# == Table: fixed_assets
#
#  allocation_account_id   :integer          not null
#  ceded                   :boolean
#  ceded_on                :date
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string           not null
#  current_amount          :decimal(19, 4)
#  custom_fields           :jsonb
#  depreciable_amount      :decimal(19, 4)   not null
#  depreciated_amount      :decimal(19, 4)   not null
#  depreciation_method     :string           not null
#  depreciation_percentage :decimal(19, 4)
#  description             :text
#  expenses_account_id     :integer
#  id                      :integer          not null, primary key
#  journal_id              :integer          not null
#  lock_version            :integer          default(0), not null
#  name                    :string           not null
#  number                  :string           not null
#  purchase_amount         :decimal(19, 4)
#  purchase_id             :integer
#  purchase_item_id        :integer
#  purchased_on            :date
#  sale_id                 :integer
#  sale_item_id            :integer
#  started_on              :date             not null
#  stopped_on              :date             not null
#  updated_at              :datetime         not null
#  updater_id              :integer
#

class FixedAsset < Ekylibre::Record::Base
  include Attachable
  include Customizable
  acts_as_numbered
  enumerize :depreciation_method, in: [:simplified_linear, :linear], predicates: { prefix: true } # graduated
  refers_to :currency
  belongs_to :expenses_account, class_name: 'Account'
  belongs_to :allocation_account, class_name: 'Account'
  belongs_to :journal, class_name: 'Journal'
  belongs_to :purchase_item, inverse_of: :fixed_asset
  belongs_to :purchase
  has_many :depreciations, -> { order(:position) }, class_name: 'FixedAssetDepreciation'
  has_many :parcel_items, through: :purchase_item
  has_many :delivery_products, through: :parcel_items, source: :product
  has_many :products
  has_many :planned_depreciations, -> { order(:position).where('NOT locked OR accounted_at IS NULL') }, class_name: 'FixedAssetDepreciation', dependent: :destroy
  has_one :tool, class_name: 'Equipment'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :ceded, inclusion: { in: [true, false] }, allow_blank: true
  validates :ceded_on, :purchased_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :allocation_account, :currency, :depreciation_method, :journal, presence: true
  validates :current_amount, :depreciation_percentage, :purchase_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :depreciable_amount, :depreciated_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, :number, presence: true, length: { maximum: 500 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(fixed_asset) { fixed_asset.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]
  validates :name, uniqueness: true
  validates :depreciation_method, inclusion: { in: depreciation_method.values }

  accepts_nested_attributes_for :products, reject_if: :all_blank, allow_destroy: false

  before_validation(on: :create) do
    self.depreciated_amount ||= 0
  end

  before_validation do
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
      if fy = FinancialYear.reorder(:started_on).first
        unless fy.started_on <= started_on
          errors.add(:started_on, :greater_than_or_equal_to, count: fy.started_on.l)
        end
      end
      if self.stopped_on
        unless self.stopped_on > started_on
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
    [:depreciable_amount, :started_on, :stopped_on, :depreciation_method, :depreciation_percentage, :currency].each do |attr|
      @auto_depreciate = true if send(attr) != old.send(attr)
    end
  end

  after_save do
    if purchase_item
      # Link products to fixed asset
      delivery_products.each do |product|
        product.fixed_asset = self
        unless product.save
          Rails.logger.warn('Cannot link fixed_asset to its products automatically')
        end
      end
    end
    depreciate! if @auto_depreciate
  end

  def depreciate!
    planned_depreciations.clear
    # Computes periods
    starts = [started_on, self.stopped_on + 1]
    starts += depreciations.pluck(:started_on)

    FinancialYear.at(self.stopped_on)
    for financial_year in FinancialYear.where(started_on: started_on..self.stopped_on).reorder(:started_on)
      start = financial_year.started_on
      starts << start if started_on <= start && start <= self.stopped_on
    end
    starts = starts.uniq.sort
    send("depreciate_with_#{depreciation_method}_method", starts)
    self
  end

  # Depreciate using linear method
  def depreciate_with_linear_method(starts)
    depreciable_days = duration.round(2)
    depreciable_amount = self.depreciable_amount
    for depreciation in depreciations
      depreciable_days -= depreciation.duration.round(2)
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    starts.each_with_index do |start, index|
      next if starts[index + 1].nil?
      unless depreciation = depreciations.find_by(started_on: start)
        depreciation = depreciations.new(started_on: start, stopped_on: starts[index + 1] - 1)
        duration = depreciation.duration.round(2)
        depreciation.amount = [remaining_amount, currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
        remaining_amount -= depreciation.amount
      end
      depreciation.financial_year = FinancialYear.at(depreciation.started_on)

      depreciation.position = position
      position += 1
      unless depreciation.save
        raise 'AAAAAAAAAAAAAAAAAAAARrrrrrrrrrrrrrrrrr' + depreciation.errors.inspect
      end
    end
  end

  # Depreciate using simplified linear method
  # Years have 12 months with 30 days
  def depreciate_with_simplified_linear_method(starts)
    depreciable_days = duration
    depreciable_amount = self.depreciable_amount
    for depreciation in reload.depreciations
      depreciable_days -= depreciation.duration
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    starts.each_with_index do |start, index|
      next if starts[index + 1].nil?
      unless depreciation = depreciations.find_by(started_on: start)
        depreciation = depreciations.new(started_on: start, stopped_on: starts[index + 1] - 1)
        duration = depreciation.duration
        depreciation.amount = [remaining_amount, currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
        remaining_amount -= depreciation.amount
      end
      depreciation.financial_year = FinancialYear.at(depreciation.started_on)

      depreciation.position = position
      position += 1
      depreciation.save!
    end
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
