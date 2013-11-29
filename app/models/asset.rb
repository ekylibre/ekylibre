# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: assets
#
#  allocation_account_id   :integer          not null
#  ceded                   :boolean          
#  ceded_on                :date             
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
#  purchased_on            :date             
#  sale_id                 :integer          
#  sale_item_id            :integer          
#  started_on              :date             not null
#  stopped_on              :date             not null
#  updated_at              :datetime         not null
#  updater_id              :integer          
#

class Asset < Ekylibre::Record::Base
  # attr_accessible :name, :started_on, :stopped_on, :description, :currency, :depreciation_method
  acts_as_numbered
  enumerize :depreciation_method, in: [:simplified_linear, :linear], predicates: {prefix: true} # graduated
  belongs_to :charges_account, class_name: "Account"
  belongs_to :allocation_account, class_name: "Account"
  belongs_to :journal, class_name: "Journal"
  has_many :depreciations, -> { order(:position) }, class_name: "AssetDepreciation"
  has_many :products
  has_many :planned_depreciations, -> { order(:position).where("NOT locked OR accounted_at IS NULL") }, class_name: "AssetDepreciation", dependent: :destroy
  has_one :tool, class_name: "Equipment"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :current_amount, :depreciable_amount, :depreciated_amount, :depreciation_percentage, :purchase_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :depreciation_method, :name, :number, allow_nil: true, maximum: 255
  validates_presence_of :allocation_account, :currency, :depreciable_amount, :depreciated_amount, :depreciation_method, :journal, :name, :number, :started_on, :stopped_on
  #]VALIDATORS]
  validates_uniqueness_of :name
  validates_inclusion_of :depreciation_method, in: self.depreciation_method.values

  accepts_nested_attributes_for :products, :reject_if => :all_blank, :allow_destroy => false


  # def self.deprecation_methods
  #   return DEPRECIATION_METHODS.collect do |key|
  #     [tc("depreciation_methods.#{key}"), key]
  #   end
  # end

  before_validation(on: :create) do
    self.depreciated_amount ||= 0
  end

  before_validation do
    # self.depreciable_amount ||= self.purchase_amount
    # self.started_on ||= self.purchased_on
    self.purchase_amount ||= self.depreciable_amount
    self.purchased_on ||= self.started_on
    if self.linear_method?
      self.depreciation_percentage = 100.0*365.25/(self.stopped_on - self.started_on).to_f
    elsif self.simplified_linear_method?
      self.depreciation_percentage ||= 20
      years = (100.0 / self.depreciation_percentage)
      months = (years - years.floor)*12.0
      days = (months - months.floor)*30.0
      self.stopped_on = (self.started_on >> (12 * years.floor + months.floor)) + days.floor - 1
    end
    self.currency = self.journal.currency
  end

  validate do
    if self.started_on
      if fy = FinancialYear.reorder("started_on").first
        unless fy.started_on <= self.started_on
          errors.add(:started_on, :greater_than_or_equal_to, :count => fy.started_on.l)
        end
      end
      if self.stopped_on
        unless self.stopped_on >= self.started_on
          errors.add(:started_on, :less_than_or_equal_to, :count => self.stopped_on.l)
        end
      end
    end
  end

  before_create do
    @auto_depreciate = true
  end

  before_update do
    @auto_depreciate = false
    old = self.class.find(self.id)
    for attr in [:depreciable_amount, :started_on, :stopped_on, :depreciation_method, :depreciation_percentage, :currency]
      @auto_depreciate = true if self.send(attr) != old.send(attr)
    end
    return true
  end

  after_save do
    self.depreciate! if @auto_depreciate
  end

  # def linear_method?
  #   return (self.depreciation_method == 'linear' ? true : false)
  # end

  # def simplified_linear_method?
  #   return (self.depreciation_method == 'simplified_linear' ? true : false)
  # end

  def depreciate!
    self.planned_depreciations.clear

    # Computes periods
    starts = [self.started_on, self.stopped_on + 1]
    for depreciation in self.depreciations
      starts << depreciation.started_on
    end
    last = FinancialYear.at(self.stopped_on)
    FinancialYear.find_each do |financial_year|
      start = financial_year.started_on
      if self.started_on <= start and start <= self.stopped_on
        starts << start
      end
    end
    starts = starts.uniq.sort
    self.send("depreciate_with_#{self.depreciation_method}_method", starts)
    return self
  end


  # Depreciate using linear method
  def depreciate_with_linear_method(starts)
    depreciable_days = ((self.stopped_on - self.started_on) + 1).to_d
    depreciable_amount = self.depreciable_amount
    for depreciation in self.depreciations
      depreciable_days -= ((depreciation.stopped_on - depreciation.started_on) + 1).to_d
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    starts.each_with_index do |start, index|
      unless starts[index + 1].nil? # Last
        depreciation = self.depreciations.where(:started_on => start).first
        if depreciation

        else
          depreciation = self.depreciations.new(:started_on => start, :stopped_on => (starts[index+1]-1))
          duration = ((depreciation.stopped_on - depreciation.started_on) + 1).to_d
          depreciation.amount = [remaining_amount, self.currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
          remaining_amount -= depreciation.amount
        end
        fy = FinancialYear.where("started_on <= ? AND ? <= stopped_on", depreciation.started_on, depreciation.stopped_on).first
        depreciation.financial_year = fy if fy

        depreciation.position = position
        position += 1
        depreciation.save!
      end
    end

  end

  # Depreciate using simplified linear method
  # Years have 12 months with 30 days
  def depreciate_with_simplified_linear_method(starts)
    depreciable_days = self.duration
    depreciable_amount = self.depreciable_amount
    for depreciation in self.reload.depreciations
      depreciable_days -= self.duration(depreciation.started_on, depreciation.stopped_on)
      depreciable_amount -= depreciation.amount
    end

    # Create it if not exists?
    remaining_amount = depreciable_amount.to_d
    position = 1
    starts.each_with_index do |start, index|
      unless starts[index + 1].nil? # Last
        depreciation = self.depreciations.where(:started_on => start).first
        unless depreciation
          depreciation = self.depreciations.new(:started_on => start, :stopped_on => (starts[index+1]-1))
          duration = self.duration(depreciation.started_on, depreciation.stopped_on)
          depreciation.amount = [remaining_amount, self.currency.to_currency.round(depreciable_amount * duration / depreciable_days)].min
          remaining_amount -= depreciation.amount
        end

        fy = FinancialYear.where("started_on <= ? AND ? <= stopped_on", depreciation.started_on, depreciation.stopped_on).first
        depreciation.financial_year = fy if fy

        depreciation.position = position
        position += 1
        depreciation.save!
      end
    end

  end


  def duration(start=nil, stopp=nil)
    start ||= self.started_on
    stopp ||= self.stopped_on
    days = 0
    if self.depreciation_method == 'simplified_linear'
      sa = ((start.day >= 30 || (start.end_of_month == start)) ? 30 : start.day)
      so = ((stopp.day >= 30 || (stopp.end_of_month == stopp)) ? 30 : stopp.day)
      cursor = start
      if start == start.end_of_month or start.day >= 30
        days += 1
        cursor = start.end_of_month + 1
      elsif start.month == stopp.month and start.year == stopp.year
        days += (so - sa).to_i + 1
        cursor = stopp
      elsif start != start.beginning_of_month
        days += (30 - sa).to_i + 1
        cursor = start.end_of_month + 1
      end
      while (cursor < stopp.beginning_of_month)
        cursor = cursor >> 1
        days += 30
      end
      if cursor < stopp
        days += [30, (so - cursor.day + 1)].min
      end
    else
      days = (stopp - start).to_i
    end
    return days.to_d
  end

end
