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
# == Table: sensors
#
#  access_parameters    :json
#  active               :boolean          default(TRUE), not null
#  battery_level        :decimal(19, 4)
#  created_at           :datetime         not null
#  creator_id           :integer
#  custom_fields        :jsonb
#  embedded             :boolean          default(FALSE), not null
#  euid                 :string
#  host_id              :integer
#  id                   :integer          not null, primary key
#  last_transmission_at :datetime
#  lock_version         :integer          default(0), not null
#  model_euid           :string
#  name                 :string           not null
#  partner_url          :string
#  product_id           :integer
#  retrieval_mode       :string           not null
#  token                :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#  vendor_euid          :string
#
require 'test_helper'

class SensorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
