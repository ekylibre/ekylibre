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
# == Table: economic_cash_indicators
#
#  activity_budget_id        :integer(4)
#  activity_budget_item_id   :integer(4)
#  activity_id               :integer(4)
#  amount                    :decimal(, )
#  campaign_id               :integer(4)
#  context                   :string
#  context_color             :string
#  created_at                :datetime         not null
#  creator_id                :integer(4)
#  direction                 :string
#  id                        :integer(4)       not null, primary key
#  loan_id                   :integer(4)
#  lock_version              :integer(4)       default(0), not null
#  nature                    :string
#  origin                    :string
#  paid_on                   :date
#  pretax_amount             :decimal(, )
#  product_nature_variant_id :integer(4)
#  updated_at                :datetime         not null
#  updater_id                :integer(4)
#  used_on                   :date
#  worker_contract_id        :integer(4)
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

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :amount, :pretax_amount, numericality: true, allow_blank: true
  validates :context, :context_color, length: { maximum: 500 }, allow_blank: true
  validates :paid_on, :used_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  # ]VALIDATORS]

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
