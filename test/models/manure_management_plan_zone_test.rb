# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: manure_management_plan_zones
#
#  absorbed_nitrogen_at_opening                    :decimal(19, 4)
#  activity_production_id                          :integer          not null
#  administrative_area                             :string
#  computation_method                              :string           not null
#  created_at                                      :datetime         not null
#  creator_id                                      :integer
#  cultivation_variety                             :string
#  expected_yield                                  :decimal(19, 4)
#  humus_mineralization                            :decimal(19, 4)
#  id                                              :integer          not null, primary key
#  intermediate_cultivation_residue_mineralization :decimal(19, 4)
#  irrigation_water_nitrogen                       :decimal(19, 4)
#  lock_version                                    :integer          default(0), not null
#  maximum_nitrogen_input                          :decimal(19, 4)
#  meadow_humus_mineralization                     :decimal(19, 4)
#  mineral_nitrogen_at_opening                     :decimal(19, 4)
#  nitrogen_at_closing                             :decimal(19, 4)
#  nitrogen_input                                  :decimal(19, 4)
#  nitrogen_need                                   :decimal(19, 4)
#  organic_fertilizer_mineral_fraction             :decimal(19, 4)
#  plan_id                                         :integer          not null
#  previous_cultivation_residue_mineralization     :decimal(19, 4)
#  soil_nature                                     :string
#  soil_production                                 :decimal(19, 4)
#  updated_at                                      :datetime         not null
#  updater_id                                      :integer
#
require 'test_helper'

class ManureManagementPlanZoneTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
