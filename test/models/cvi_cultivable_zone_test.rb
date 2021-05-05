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
# == Table: cvi_cultivable_zones
#
#  calculated_area_unit  :string
#  calculated_area_value :decimal(19, 4)
#  created_at            :datetime         not null
#  creator_id            :integer
#  cvi_statement_id      :integer
#  declared_area_unit    :string
#  declared_area_value   :decimal(19, 4)
#  id                    :integer          not null, primary key
#  land_parcels_status   :string           default("not_started")
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  shape                 :polygon          not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#
require 'test_helper'

class CviCultivableZoneTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'is creatable' do
    resource = create(:cvi_cultivable_zone)
    first_resource = CviCultivableZone.last
    assert_equal resource, first_resource
  end

  test 'responds to calculated_area  with measure object' do
    resource = create(:cvi_cultivable_zone)
    assert_equal 'Measure', resource.calculated_area.class.name
  end

  test 'responds to declared_area  with measure object' do
    resource = create(:cvi_cultivable_zone)
    assert_equal 'Measure', resource.declared_area.class.name
  end

  test 'has calculated_area setted when shape change' do
    resource = create(:cvi_cultivable_zone)
    assert_in_delta Measure.new(resource.reload.shape.area, :square_meter).convert(:hectare).value, resource.reload.calculated_area_value, delta = 0.0001
    shape = FFaker::Shape.polygon
    resource.update(shape: shape)
    assert_in_delta Measure.new(shape.area, :square_meter).convert(:hectare).value, resource.reload.calculated_area_value, delta = 0.0001
  end
end
