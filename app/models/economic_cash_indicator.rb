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
# == Table: intervention_costings
#
#  created_at      :datetime
#  creator_id      :integer
#  doers_cost      :decimal(, )
#  id              :integer          not null, primary key
#  inputs_cost     :decimal(, )
#  lock_version    :integer          default(0), not null
#  receptions_cost :decimal(, )
#  tools_cost      :decimal(, )
#  updated_at      :datetime
#  updater_id      :integer
#
class EconomicCashIndicator < ApplicationRecord
  enumerize :direction, in: %i[revenue expense], predicates: true
  enumerize :origin, in: %i[manual itk automatic contract loan], predicates: true
  enumerize :nature, in: %i[static dynamic permanent_worker temporary_worker external_staff], predicates: true

  belongs_to :campaign
  belongs_to :activity
  belongs_to :activity_budget
  belongs_to :activity_budget_item, inverse_of: :economic_cash_indicators
  belongs_to :product_nature_variant
  belongs_to :worker_contract, inverse_of: :economic_cash_indicators
  belongs_to :loan, inverse_of: :economic_cash_indicators

  scope :of_campaign, ->(campaign) { where(campaign: campaign)}
  scope :of_context, ->(context) { where(context: context)}
  scope :of_activity, ->(activity) { where(activity: activity)}
  scope :of_activity_budget, ->(activity_budget) { where(activity_budget: activity_budget)}
  scope :of_product_nature_variant, ->(product_nature_variant) { where(product_nature_variant: product_nature_variant)}
  scope :revenues, -> { where(direction: :revenue) }
  scope :expenses, -> { where(direction: :expense) }

  delegate :currency, to: :activity_budget

  scope :paid_between, lambda { |started_on, stopped_on|
    where(paid_on: started_on..stopped_on)
  }

  scope :used_between, lambda { |started_on, stopped_on|
    where(used_on: started_on..stopped_on)
  }
end
