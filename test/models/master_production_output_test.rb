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
# == Table: master_production_outputs
#
#  analysis_items         Array<:string>
#  average_yield          :decimal(19, 4)
#  main                   :boolean          default(FALSE), not null
#  name                   :string           not null
#  production_nature_id   :integer          not null
#  production_system_name :string           not null
#
require 'test_helper'

class MasterProductionOutputTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Add tests here...
end
