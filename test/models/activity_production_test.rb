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
# == Table: activity_productions
#
#  activity_id        :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  cultivable_zone_id :integer
#  id                 :integer          not null, primary key
#  irrigated          :boolean          default(FALSE), not null
#  lock_version       :integer          default(0), not null
#  nitrate_fixing     :boolean          default(FALSE), not null
#  rank_number        :integer          not null
#  size_indicator     :string           not null
#  size_unit          :string
#  size_value         :decimal(19, 4)   not null
#  started_at         :datetime
#  state              :string
#  stopped_at         :datetime
#  support_id         :integer          not null
#  support_shape      :geometry({:srid=>4326, :type=>"geometry"})
#  updated_at         :datetime         not null
#  updater_id         :integer
#  usage              :string           not null
#
require 'test_helper'

class ActivityProductionTest < ActiveSupport::TestCase
  # Add tests here...
end
