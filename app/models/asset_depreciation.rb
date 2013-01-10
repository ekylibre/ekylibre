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
# == Table: asset_depreciations
#
#  accountable        :boolean          not null
#  accounted_at       :datetime         
#  amount             :decimal(19, 4)   not null
#  asset_amount       :decimal(19, 4)   
#  asset_id           :integer          not null
#  created_at         :datetime         not null
#  created_on         :date             not null
#  creator_id         :integer          
#  depreciated_amount :decimal(19, 4)   
#  depreciation       :text             
#  financial_year_id  :integer          
#  id                 :integer          not null, primary key
#  journal_entry_id   :integer          
#  lock_version       :integer          default(0), not null
#  position           :integer          
#  protected          :boolean          not null
#  started_on         :date             not null
#  stopped_on         :date             not null
#  updated_at         :datetime         not null
#  updater_id         :integer          
#
class AssetDepreciation < CompanyRecord
  attr_accessible :accountable, :amount, :asset_amount, :asset_id, :created_on, :depreciation, :financial_year_id, :position
  acts_as_list :scope => :asset
  belongs_to :asset
  belongs_to :financial_year
  belongs_to :journal_entry
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :asset_amount, :depreciated_amount, :allow_nil => true
  validates_inclusion_of :accountable, :protected, :in => [true, false]
  validates_presence_of :amount, :asset, :created_on, :started_on, :stopped_on
  #]VALIDATORS]
  validates_presence_of :financial_year
  delegate :currency, :to => :asset

  sums :asset, :depreciations, :amount => :depreciated_amount

  bookkeep(:on => :nothing) do |b|
    b.journal_entry do |entry|

    end
  end

  before_validation(:on => :create) do
    self.created_on = Date.today
  end

  before_validation do
    self.depreciated_amount = self.asset.depreciations.where("stopped_on < ?", self.started_on).sum(:amount) + self.amount
    self.asset_amount = self.asset.depreciable_amount - self.depreciated_amount
  end

  validate do
    # A start day must be the depreciation start or a financial year start
    unless self.started_on == self.asset.started_on or self.started_on.beginning_of_month == self.started_on
      errors.add(:started_on, :invalid_date, :start => self.asset.started_on)
    end
  end


end
