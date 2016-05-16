# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: inspections
#
#  activity_id                    :integer          not null
#  comment                        :text
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  id                             :integer          not null, primary key
#  implanter_application_width    :decimal(19, 4)
#  implanter_rows_number          :integer
#  implanter_working_width        :decimal(19, 4)
#  lock_version                   :integer          default(0), not null
#  number                         :string           not null
#  product_id                     :integer          not null
#  product_net_surface_area_unit  :string
#  product_net_surface_area_value :decimal(19, 4)
#  sampled_at                     :datetime         not null
#  sampling_distance              :decimal(19, 4)
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#
require 'test_helper'

class InspectionTest < ActiveSupport::TestCase
  # Add tests here...
end
