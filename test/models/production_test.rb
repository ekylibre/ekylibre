# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: productions
#
#  activity_id          :integer          not null
#  campaign_id          :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  homogeneous_expenses :boolean
#  homogeneous_revenues :boolean
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string           not null
#  position             :integer
#  started_at           :datetime
#  state                :string           not null
#  static_support       :boolean          not null
#  stopped_at           :datetime
#  support_variant_id   :integer
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variant_id           :integer
#  working_indicator    :string
#  working_unit         :string
#
require 'test_helper'

class ProductionTest < ActiveSupport::TestCase
  test_fixtures
end
