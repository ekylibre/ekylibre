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
# == Table: activity_budgets
#
#  activity_id  :integer          not null
#  campaign_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  currency     :string           not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ActivityBudget < Ekylibre::Record::Base
  belongs_to :activity
  belongs_to :campaign
  has_many :items, class_name: 'ActivityBudgetItem', dependent: :destroy, inverse_of: :activity_budget
  has_many :expenses, -> { expenses }, class_name: 'ActivityBudgetItem', inverse_of: :activity_budget
  has_many :revenues, -> { revenues }, class_name: 'ActivityBudgetItem', inverse_of: :activity_budget

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :activity, :campaign, :currency
  # ]VALIDATORS]
  validates_associated :expenses, :revenues

  scope :of_campaign, ->(campaign) { where(campaign: campaign) }
  scope :of_activity, ->(activity) { where(activity: activity) }

  accepts_nested_attributes_for :expenses, :revenues, reject_if: :all_blank, allow_destroy: true

  delegate :name, to: :activity, prefix: true
  delegate :name, to: :campaign, prefix: true
  delegate :size_indicator, :size_unit, to: :activity

  before_validation on: :create do
    self.currency ||= Preference[:currency]
  end

  def expenses_amount
    expenses.sum(:amount)
  end

  def revenues_amount
    revenues.sum(:amount)
  end

  def name
    tc(:name, activity_name: activity_name, campaign_name: campaign_name)
  end

  def currency_precision
    Nomen::Currency.find(currency).precision
  end

  def productions
    return ActivityProduction.none if activity.nil?
    activity.productions.of_campaign(campaign)
  end

  def any_production?
    productions.any?
  end

  def productions_size
    productions.map(&:size_value).sum
  end

  delegate :count, to: :productions, prefix: true

  def computation_methods
    list = []
    if productions_size.to_f != 0
      list << :per_working_unit
      list << :per_production
    elsif productions_count.to_f != 0
      list << :per_production
    end
    list << :per_campaign
    list
  end

  # Duplicate current budget in given activity and campaign
  def duplicate!(activity, campaign)
    budget = ActivityBudget.find_or_create_by!(activity: activity, campaign: campaign)
    items.each do |item|
      item.duplicate!(activity_budget: budget)
    end
    budget
  end
end
