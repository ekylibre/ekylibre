# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: cultivable_zones
#
#  codes                  :jsonb
#  created_at             :datetime         not null
#  creator_id             :integer
#  custom_fields          :jsonb
#  description            :text
#  farmer_id              :integer
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string           not null
#  owner_id               :integer
#  production_system_name :string
#  shape                  :geometry({:srid=>4326, :type=>"multi_polygon"}) not null
#  soil_nature            :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#  uuid                   :uuid
#  work_number            :string           not null
#
require 'test_helper'

class CultivableZoneTest < ActiveSupport::TestCase
  test_model_actions
  # Add tests here...
end
