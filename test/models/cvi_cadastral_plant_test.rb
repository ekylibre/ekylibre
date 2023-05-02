# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: cvi_cadastral_plants
#
#  area_unit                       :string
#  area_value                      :decimal(19, 4)
#  cadastral_ref_updated           :boolean          default(FALSE)
#  created_at                      :datetime         not null
#  creator_id                      :integer(4)
#  cvi_cultivable_zone_id          :integer(4)
#  cvi_statement_id                :integer(4)
#  designation_of_origin_id        :integer(4)
#  id                              :integer(4)       not null, primary key
#  inter_row_distance_unit         :string
#  inter_row_distance_value        :decimal(19, 4)
#  inter_vine_plant_distance_unit  :string
#  inter_vine_plant_distance_value :decimal(19, 4)
#  land_modification_date          :date
#  land_parcel_id                  :string
#  land_parcel_number              :string
#  lock_version                    :integer(4)       default(0), not null
#  planting_campaign               :string
#  rootstock_id                    :string
#  section                         :string           not null
#  state                           :string           not null
#  type_of_occupancy               :string
#  updated_at                      :datetime         not null
#  updater_id                      :integer(4)
#  vine_variety_id                 :string
#  work_number                     :string           not null
#
require 'test_helper'

class CviCadastralPlantTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'is creatable' do
    cvi_cadastral_plant = create(:cvi_cadastral_plant)
    first_cvi_cadastral_plant = CviCadastralPlant.last
    assert_equal cvi_cadastral_plant, first_cvi_cadastral_plant
  end

  test 'responds to area, inter_row_distance, inter_vine_plant_distance  with measure object' do
    cvi_cadastral_plant = create(:cvi_cadastral_plant)
    assert_equal 'Measure', cvi_cadastral_plant.area.class.name
    assert_equal 'Measure', cvi_cadastral_plant.inter_row_distance.class.name
    assert_equal 'Measure', cvi_cadastral_plant.inter_vine_plant_distance.class.name
  end

  test 'validates presence of land_parcel only on update' do
    cvi_cadastral_plant = build(:cvi_cadastral_plant, land_parcel_id: nil)
    assert_equal true, cvi_cadastral_plant.valid?
    cvi_cadastral_plant.save
    cvi_cadastral_plant.location = create(:location)
    cvi_cadastral_plant.update(land_parcel_id: nil)
    assert_equal false, cvi_cadastral_plant.valid?
  end
end
