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
# == Table: planning_scenario_activities
#
#  activity_id          :integer(4)
#  created_at           :datetime         not null
#  creator_id           :integer(4)
#  id                   :integer(4)       not null, primary key
#  planning_scenario_id :integer(4)
#  updated_at           :datetime         not null
#  updater_id           :integer(4)
#

class ScenarioActivity < ApplicationRecord
  self.table_name = "planning_scenario_activities"
  belongs_to :scenario, class_name: 'Scenario', foreign_key: :planning_scenario_id
  belongs_to :activity, class_name: 'Activity', foreign_key: :activity_id
  has_many :plots, class_name: 'ScenarioActivity::Plot', foreign_key: :planning_scenario_activity_id, dependent: :destroy
  has_many :animals, class_name: 'ScenarioActivity::Animal', foreign_key: :planning_scenario_activity_id, dependent: :destroy
  accepts_nested_attributes_for :plots, allow_destroy: true
  accepts_nested_attributes_for :animals, allow_destroy: true

  validates :activity, presence: true

  def activity_name
    activity.name
  end
end
