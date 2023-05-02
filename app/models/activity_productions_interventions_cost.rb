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
# == Table: activity_productions_interventions_costs
#
#  activity_production_id :integer(4)
#  doers                  :decimal(, )
#  inputs                 :decimal(, )
#  intervention_id        :integer(4)
#  receptions             :decimal(, )
#  target_id              :integer(4)
#  tools                  :decimal(, )
#  total                  :decimal(, )
#
class ActivityProductionsInterventionsCost < ApplicationRecord

  belongs_to :activity_production
  belongs_to :intervention
  belongs_to :target

  scope :of_intervention, ->(intervention) { where(intervention: intervention)}
  scope :of_activity_production, ->(activity_production) { where(activity_production: activity_production)}

  def readonly?
    true
  end

end
