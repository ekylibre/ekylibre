# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: cvi_statements
#
#  cadastral_plant_count     :integer          default(0)
#  cadastral_sub_plant_count :integer          default(0)
#  campaign_id               :integer
#  created_at                :datetime         not null
#  creator_id                :integer
#  cvi_number                :string           not null
#  declarant                 :string           not null
#  extraction_date           :date             not null
#  farm_name                 :string           not null
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  siret_number              :string           not null
#  state                     :string           not null
#  total_area_unit           :string
#  total_area_value          :decimal(19, 4)
#  updated_at                :datetime         not null
#  updater_id                :integer
#
require 'test_helper'

class CviStatementTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'is creatable' do
    cvi_statement = create(:cvi_statement)
    assert_equal cvi_statement, CviStatement.find(cvi_statement.id)
  end

  test 'responds to area, inter_row_distance, inter_vine_plant_distance with measure object' do
    cvi_cadastral_plant = create(:cvi_statement)
    assert_equal 'Measure', cvi_cadastral_plant.total_area.class.name
  end

  test 'is not valid if siret_number is invalid' do
    cvi_statement = build(:cvi_statement, siret_number: 12_323_131)
    refute cvi_statement.valid?
  end

  test "convertible? return false if one cvi cadastral plant don't have cadastral land parcel" do
    cvi_statement = create(:cvi_statement, :with_cvi_cadastral_plants)
    cvi_statement.cvi_cadastral_plants.first.update_attribute('land_parcel_id', nil)
    refute cvi_statement.convertible?
  end
end
