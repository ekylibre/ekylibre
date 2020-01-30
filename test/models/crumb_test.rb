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
# == Table: crumbs
#
#  accuracy                      :decimal(19, 4)   not null
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  device_uid                    :string           not null
#  geolocation                   :geometry({:srid=>4326, :type=>"st_point"}) not null
#  id                            :integer          not null, primary key
#  intervention_parameter_id     :integer
#  intervention_participation_id :integer
#  lock_version                  :integer          default(0), not null
#  metadata                      :text
#  nature                        :string           not null
#  read_at                       :datetime         not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  user_id                       :integer
#
require 'test_helper'

class CrumbTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
