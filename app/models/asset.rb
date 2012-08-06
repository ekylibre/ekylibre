# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
#  account_id          :integer          not null
#  ceded               :boolean          
#  ceded_on            :date             
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  currency            :string(3)        
#  current_amount      :decimal(19, 4)   
#  depreciable_amount  :decimal(19, 4)   not null
#  depreciated_amount  :decimal(19, 4)   not null
#  depreciation_method :string(255)      not null
#  description         :text             
#  id                  :integer          not null, primary key
#  journal_id          :integer          not null
#  lock_version        :integer          default(0), not null
#  name                :string(255)      not null
#  number              :string(255)      not null
#  purchase_amount     :decimal(19, 4)   
#  purchase_id         :integer          
#  purchase_line_id    :integer          
#  purchased_on        :date             
#  sale_id             :integer          
#  sale_line_id        :integer          
#  started_on          :date             not null
#  stopped_on          :date             not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#

class Asset < CompanyRecord
  DEPRECIATION_METHODS = ['linear', 'graduated']
  acts_as_numbered
  belongs_to :account
  belongs_to :journal
  has_many :depreciations, :class_name => "AssetDepreciation", :order => :position
  has_many :planned_depreciations, :class_name => "AssetDepreciation", :order => :position, :conditions => "NOT protected OR accounted_at IS NULL", :dependent => :destroy
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :current_amount, :depreciable_amount, :depreciated_amount, :purchase_amount, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :depreciation_method, :name, :number, :allow_nil => true, :maximum => 255
  validates_presence_of :account, :company, :depreciable_amount, :depreciated_amount, :depreciation_method, :journal, :name, :number, :started_on, :stopped_on
  #]VALIDATORS]
  validates_uniqueness_of :name

  def self.deprecation_methods
    return DEPRECIATION_METHODS.collect do |key|
      [tc("depreciation_methods.#{key}"), key]
    end
  end

  before_validation(:on => :create) do
    self.depreciated_amount ||= 0
  end

  before_validation do
    # self.depreciable_amount ||= self.purchase_amount
    # self.started_on ||= self.purchased_on
    self.purchase_amount ||= self.depreciable_amount
    self.purchased_on ||= self.started_on
    self.currency = self.journal.currency
  end

  validate do
    if self.stopped_on and self.started_on
      errors.add(:stopped_on, :less_than_or_equal_to, :count => self.stopped_on) unless self.stopped_on >= self.started_on
    end
  end

  def depreciate!
    self.planned_depreciations.clear

    # Computes periods
    cut_on = (self.company.current_financial_year.stopped_on + 1)
    starts = [self.started_on, self.stopped_on + 1]
    for depreciation in self.depreciations
      starts << depreciation.started_on
    end
    for year in self.started_on.year..self.stopped_on.year
      start = Date.civil(year, cut_on.month, cut_on.day)
      if !starts.include?(start) and self.started_on <= start and start <= self.stopped_on
        starts << start 
      end
    end
    starts.sort!

    depreciable_days = ((self.stopped_on - self.started_on) + 1).to_d
    depreciable_amount = self.depreciable_amount
    for depreciation in self.depreciations
      depreciable_days  -= ((depreciation.stopped_on - depreciation.started_on) + 1).to_d
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
        puts [remaining_amount, depreciation.amount].inspect
        depreciation.position = position
        position += 1
        depreciation.save!
      end
    end
  end


end
