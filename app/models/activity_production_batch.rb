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
# == Table: activity_production_batches
#
#  activity_production_id             :integer(4)
#  created_at                         :datetime         not null
#  day_interval                       :integer(4)
#  id                                 :integer(4)       not null, primary key
#  irregular_batch                    :boolean          default(FALSE)
#  number                             :integer(4)
#  planning_scenario_activity_plot_id :integer(4)
#  updated_at                         :datetime         not null
#

class ActivityProductionBatch < ApplicationRecord

  validates :number, :day_interval, presence: true, unless: :irregular_batch?
  validates :number, :day_interval, numericality: { greater_than: 0 }, unless: :irregular_batch?

  belongs_to :activity_production, class_name: 'ActivityProduction'
  belongs_to :plot, class_name: 'ScenarioActivity::Plot', foreign_key: :planning_scenario_activity_plot_id
  has_many :irregular_batches, class_name: 'ActivityProductionIrregularBatch', dependent: :destroy, foreign_key: :activity_production_batch_id, inverse_of: :activity_production_batch

  accepts_nested_attributes_for :irregular_batches, allow_destroy: true

  before_validation do
    irregular_batches.destroy_all unless irregular_batch
  end
end
