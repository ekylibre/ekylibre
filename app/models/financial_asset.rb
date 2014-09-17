# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: financial_assets
#
#  allocation_account_id   :integer          not null
#  ceded                   :boolean
#  ceded_at                :datetime
#  charges_account_id      :integer
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string(3)        not null
#  current_amount          :decimal(19, 4)
#  depreciable_amount      :decimal(19, 4)   not null
#  depreciated_amount      :decimal(19, 4)   not null
#  depreciation_method     :string(255)      not null
#  depreciation_percentage :decimal(19, 4)
#  description             :text
#  id                      :integer          not null, primary key
#  journal_id              :integer          not null
#  lock_version            :integer          default(0), not null
#  name                    :string(255)      not null
#  number                  :string(255)      not null
#  purchase_amount         :decimal(19, 4)
#  purchase_id             :integer
#  purchase_item_id        :integer
#  purchased_at            :datetime
#  sale_id                 :integer
#  sale_item_id            :integer
#  started_at              :datetime         not null
#  stopped_at              :datetime         not null
#  updated_at              :datetime         not null
#  updater_id              :integer
#

class FinancialAsset < Ekylibre::Record::Base
  acts_as_numbered
  enumerize :depreciation_method, in: [:simplified_linear, :linear], predicates: {prefix: true} # graduated
  enumerize :currency, in: Nomen::Currencies.all, default: Proc.new { Preference[:currency] }
  belongs_to :charges_account, class_name: "Account"
  belongs_to :allocation_account, class_name: "Account"
  belongs_to :journal, class_name: "Journal"
  has_many :depreciations, -> { order(:position) }, class_name: "FinancialAssetDepreciation"
  has_many :products
  has_many :planned_depreciations, -> { order(:position).where("NOT locked OR accounted_at IS NULL") }, class_name: "FinancialAssetDepreciation", dependent: :destroy
  has_one :tool, class_name: "Equipment"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :current_amount, :depreciable_amount, :depreciated_amount, :depreciation_percentage, :purchase_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :depreciation_method, :name, :number, allow_nil: true, maximum: 255
  validates_presence_of :allocation_account, :currency, :depreciable_amount, :depreciated_amount, :depreciation_method, :journal, :name, :number, :started_at, :stopped_at
  #]VALIDATORS]
  validates_uniqueness_of :name
  validates_inclusion_of :depreciation_method, in: self.depreciation_method.values

  accepts_nested_attributes_for :products, :reject_if => :all_blank, :allow_destroy => false

  before_validation(on: :create) do
    self.depreciated_amount ||= 0
  end

  before_validation do
    self.purchase_amount ||= self.depreciable_amount
    self.purchased_at ||= self.started_at
    if self.depreciation_method_linear?
      if self.stopped_at and self.started_at
        self.depreciation_percentage = 100.0 * 365.25 / self.duration
      end
    elsif self.depreciation_method_simplified_linear?
      self.depreciation_percentage ||= 20
      years = (100.0 / self.depreciation_percentage.to_f)
      # TODO fix bigdecimal interpretation
      months = (years - years.floor) * 12.0
      days = (months - months.floor) * 30.0
      self.stopped_at = self.started_at + (12 * years.floor + months.floor).months + days.floor - 1
    end
    # self.currency = self.journal.currency
    true
  end

  validate do
    if self.currency and self.journal
      errors.add(:currency, :invalid) if self.currency != self.journal.currency
    end
    if self.started_at
      if fy = FinancialYear.reorder(:started_at).first
        unless fy.started_at <= self.started_at
          errors.add(:started_at, :greater_than_or_equal_to, count: fy.started_at.l)
        end
      end
      if self.stopped_at
        unless self.stopped_at >= self.started_at
          errors.add(:started_at, :less_than_or_equal_to, count: self.stopped_at.l)
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
    old = self.class.find(self.id)
    for attr in [:depreciable_amount, :started_at, :stopped_at, :depreciation_method, :depreciation_percentage, :currency]
      @auto_depreciate = true if self.send(attr) != old.send(attr)
    end
  end

  after_save do
    self.depreciate! if @auto_depreciate
  end

  def depreciate!
    self.planned_depreciations.clear
    # Computes periods
    starts = [self.started_at, self.stopped_at + 1]
    for depreciation in self.depreciations
      starts << depreciation.started_at
    end
    last = FinancialYear.at(self.stopped_at)
    for financial_year in FinancialYear.where(started_at: self.started_at..self.stopped_at).reorder(:started_at)
      start = financial_year.started_at
      if self.started_at <= start and start <= self.stopped_at
        starts << start
      end
    end
    starts = starts.uniq.sort
    self.send("depreciate_with_#{self.depreciation_method}_method", starts)
    return self
  end


  # Depreciate using linear method
  def depreciate_with_linear_method(starts)
    depreciable_days = self.duration.round(2)
    depreciable_amount = self.depreciable_amount
    for depreciation in self.depreciations
      depreciable_days   -= depreciation.duration.round(2)
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    puts starts.inspect.yellow
    starts.each_with_index do |start, index|
      puts "START: #{start.inspect}"
      unless starts[index + 1].nil? # Last
        puts "START: #{start.inspect}".red
        unless depreciation = self.depreciations.find_by(started_at: start)
          depreciation = self.depreciations.new(started_at: start, stopped_at: starts[index+1])
          duration = depreciation.duration.round(2)
          depreciation.amount = [remaining_amount, self.currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
          remaining_amount -= depreciation.amount
        end
        depreciation.financial_year = FinancialYear.at(depreciation.started_at)

        depreciation.position = position
        position += 1
        unless depreciation.save
          raise "AAAAAAAAAAAAAAAAAAAARrrrrrrrrrrrrrrrrr" + depreciation.errors.inspect
        end
      end
    end

  end

  # Depreciate using simplified linear method
  # Years have 12 months with 30 days
  def depreciate_with_simplified_linear_method(starts)
    depreciable_days = self.duration
    depreciable_amount = self.depreciable_amount
    for depreciation in self.reload.depreciations
      depreciable_days   -= depreciation.duration
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    starts.each_with_index do |start, index|
      unless starts[index + 1].nil? # Last
        depreciation = self.depreciations.find_by(started_at: start)
        unless depreciation
          depreciation = self.depreciations.new(started_at: start, stopped_at: starts[index+1])
          duration = depreciation.duration
          depreciation.amount = [remaining_amount, self.currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
          remaining_amount -= depreciation.amount
        end
        depreciation.financial_year = FinancialYear.at(depreciation.started_at)

        depreciation.position = position
        position += 1
        depreciation.save!
      end
    end

  end


  # Returns the duration in days of all the depreciations
  def duration
    return self.class.duration(self.started_at, self.stopped_at, mode: self.depreciation_method.to_sym)
  end

  # Returns the duration in days between to 2 times
  def self.duration(started_at, stopped_at, options = {})
    days = 0
    if options[:mode] == :simplified_linear
      started_on = started_at.to_date
      stopped_on = stopped_at.to_date
      sa = ((started_on.day >= 30 || (started_on.end_of_month == started_on)) ? 30 : started_on.day)
      so = ((stopped_on.day >= 30 || (stopped_on.end_of_month == stopped_on)) ? 30 : stopped_on.day)
      cursor = started_on.to_date
      if started_on == started_on.end_of_month or started_on.day >= 30
        days += 1
        cursor = (started_on.end_of_month + 1.day).beginning_of_day
      elsif started_on.month == stopped_on.month and started_on.year == stopped_on.year
        days += (so - sa).to_i + 1
        cursor = stopped_on
      elsif started_on != started_on.beginning_of_month
        days += (30 - sa).to_i + 1
        cursor = started_on.end_of_month + 1
      end
      while (cursor < stopped_on.beginning_of_month)
        cursor = cursor + 1.month
        days += 30
      end
      if cursor < stopped_on
        days += [30, (so - cursor.day + 1)].min
      end
    else
      days = ((stopped_at - started_at) / (24 * 3600)).ceil
    end
    return days.to_f
  end

end
