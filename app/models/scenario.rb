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
# == Table: planning_scenarios
#
#  area        :decimal(, )
#  campaign_id :integer(4)
#  created_at  :datetime         not null
#  creator_id  :integer(4)
#  description :string
#  id          :integer(4)       not null, primary key
#  name        :string
#  updated_at  :datetime         not null
#  updater_id  :integer(4)
#

class Scenario < ApplicationRecord
  self.table_name = "planning_scenarios"

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :area, numericality: true, allow_blank: true
  validates :description, :name, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :name, :campaign, presence: true

  belongs_to :campaign, class_name: 'Campaign', foreign_key: :campaign_id
  has_many :scenario_activities, class_name: 'ScenarioActivity', foreign_key: :planning_scenario_id, dependent: :destroy

  accepts_nested_attributes_for :scenario_activities

  def generate_daily_charges
    plots = get_plots
    animals = get_animals
    daily_charges = []
    plots.each do |plot|
      daily_charges.concat(plot.generate_daily_charges)
    end
    animals.each do |animal|
      daily_charges.concat(animal.generate_daily_charges)
    end
    daily_charges
  end

  def rotation_area
    plots = get_plots.includes(:batch)
    plots.sum(&:total_area)
  end

  def human_rotation_area
    rotation_area.in(:hectare).l(precision: 0)
  end

  private

    # rubocop:disable Naming/AccessorMethodName
    def get_plots
      ScenarioActivity::Plot.of_scenario(self)
    end

    def get_animals
      ScenarioActivity::Animal.of_scenario(self)
    end
  # rubocop:enable Naming/AccessorMethodName
end
