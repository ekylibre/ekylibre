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
# == Table: activities
#
#  codes                        :jsonb
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  cultivation_variety          :string
#  custom_fields                :jsonb
#  description                  :text
#  family                       :string           not null
#  grading_net_mass_unit_name   :string
#  grading_sizes_indicator_name :string
#  grading_sizes_unit_name      :string
#  id                           :integer          not null, primary key
#  lock_version                 :integer          default(0), not null
#  measure_grading_items_count  :boolean          default(FALSE), not null
#  measure_grading_net_mass     :boolean          default(FALSE), not null
#  measure_grading_sizes        :boolean          default(FALSE), not null
#  name                         :string           not null
#  nature                       :string           not null
#  production_campaign          :string
#  production_cycle             :string           not null
#  production_nature_id         :integer
#  production_system_name       :string
#  size_indicator_name          :string
#  size_unit_name               :string
#  support_variety              :string
#  suspended                    :boolean          default(FALSE), not null
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  use_countings                :boolean          default(FALSE), not null
#  use_gradings                 :boolean          default(FALSE), not null
#  use_seasons                  :boolean          default(FALSE)
#  use_tactics                  :boolean          default(FALSE)
#  with_cultivation             :boolean          not null
#  with_supports                :boolean          not null
#
require 'test_helper'

class ActivityTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
