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
# == Table: master_production_natures
#
#  agroedi_crop_code  :string
#  cap_2017_crop_code :string
#  cap_2018_crop_code :string
#  cap_2019_crop_code :string
#  human_name         :jsonb
#  human_name_fra     :string           not null
#  id                 :integer          not null, primary key
#  pfi_crop_code      :string
#  season             :string
#  specie             :string           not null
#  started_on         :date             not null
#  stopped_on         :date             not null
#
require 'test_helper'

class MasterProductionNatureTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Add tests here...
end
