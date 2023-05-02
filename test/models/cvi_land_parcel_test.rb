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
# == Table: cvi_land_parcels
#
#  activity_id                     :integer(4)
#  calculated_area_unit            :string
#  calculated_area_value           :decimal(19, 5)
#  created_at                      :datetime         not null
#  creator_id                      :integer(4)
#  cvi_cultivable_zone_id          :integer(4)
#  declared_area_unit              :string
#  declared_area_value             :decimal(19, 5)
#  designation_of_origin_id        :integer(4)
#  id                              :integer(4)       not null, primary key
#  inter_row_distance_unit         :string
#  inter_row_distance_value        :decimal(19, 4)
#  inter_vine_plant_distance_unit  :string
#  inter_vine_plant_distance_value :decimal(19, 4)
#  land_modification_date          :date
#  lock_version                    :integer(4)       default(0), not null
#  name                            :string           not null
#  planting_campaign               :string
#  rootstock_id                    :string
#  shape                           :geometry({:srid=>4326, :type=>"geometry"})
#  state                           :string
#  updated_at                      :datetime         not null
#  updater_id                      :integer(4)
#  vine_variety_id                 :string
#
require 'test_helper'

class CviLandParcelTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'is creatable' do
    cvi_land_parcel = create(:cvi_land_parcel)
    first_cvi_land_parcel = CviLandParcel.last
    assert_equal cvi_land_parcel, first_cvi_land_parcel
  end

  test 'responds to calculated_area with measure object' do
    resource = create(:cvi_land_parcel)
    assert_equal 'Measure', resource.calculated_area.class.name
  end
  test 'responds to declared_area with measure object' do
    resource = create(:cvi_land_parcel)
    assert_equal 'Measure', resource.declared_area.class.name
  end
  test 'responds to inter_row_distance with measure object' do
    resource = create(:cvi_land_parcel)
    assert_equal 'Measure', resource.inter_row_distance.class.name
  end
  test 'responds to inter_vine_plant_distance with measure object' do
    resource = create(:cvi_land_parcel)
    assert_equal 'Measure', resource.inter_vine_plant_distance.class.name
  end

  test 'responds to updated? with true, if it has already been updated' do
    resource = create(:cvi_land_parcel, :with_activity)
    resource.update(attributes_for(:cvi_land_parcel))
    assert(resource.reload.updated?)
  end

  test 'has calculated_area setted when shape change' do
    resource = create(:cvi_land_parcel, :with_activity)
    assert_in_delta Measure.new(resource.reload.shape.area, :square_meter).convert(:hectare).value, resource.reload.calculated_area_value, delta = 0.00001
    shape = FFaker::Shape.polygon
    resource.update(shape: shape)
    assert_in_delta Measure.new(shape.area, :square_meter).convert(:hectare).value, resource.reload.calculated_area_value, delta = 0.00001
  end

  test 'hole outside shell shape are removed on update' do
    cvi_land_parcel = create(:cvi_land_parcel)

    shape_with_hole = Charta.new_geometry("Polygon ((3.103594779968263 43.49519949095115, 3.103192448616027 43.49521116551221, 3.10312807559967 43.49563144820679, 3.103595113965692 43.49547746379163, 3.103594779968263 43.49519949095115), (3.103348 43.4953499947257, 3.103422 43.4953434947257, 3.1034289 43.4953783947257, 3.1033567 43.4953857947257, 3.103348 43.4953499947257))")

    cvi_land_parcel.update(shape: shape_with_hole.to_rgeo)
    assert_equal(shape_with_hole.area, cvi_land_parcel.reload.shape.area, "Shape with hole inside are valid and saved")

    shape_with_hole_outside = Charta.new_geometry("SRID=4326;Polygon ((3.103594779968263 43.49519949095115, 3.103192448616027 43.49521116551221, 3.10312807559967 43.49563144820679, 3.103310465812684 43.49528802298278, 3.103594779968263 43.49519949095115), (3.103348 43.4953499947257, 3.103422 43.4953434947257, 3.1034289 43.4953783947257, 3.1033567 43.4953857947257, 3.103348 43.4953499947257))")
    shape_without_hole = Charta.new_geometry("SRID=4326;Polygon ((3.103594779968263 43.49519949095115, 3.103192448616027 43.49521116551221, 3.10312807559967 43.49563144820679, 3.103310465812684 43.49528802298278, 3.103594779968263 43.49519949095115))")

    cvi_land_parcel.update(shape: shape_with_hole_outside.to_rgeo)
    assert_in_delta(shape_without_hole.area, cvi_land_parcel.reload.shape.area, 0.00001, "Hole oustide is deleted")
  end
end
