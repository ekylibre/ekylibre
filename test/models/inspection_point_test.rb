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
# == Table: inspection_points
#
#  created_at         :datetime         not null
#  creator_id         :integer
#  id                 :integer          not null, primary key
#  inspection_id      :integer          not null
#  items_count_value  :integer
#  lock_version       :integer          default(0), not null
#  maximal_size_value :decimal(19, 4)
#  minimal_size_value :decimal(19, 4)
#  nature_id          :integer          not null
#  net_mass_value     :decimal(19, 4)
#  updated_at         :datetime         not null
#  updater_id         :integer
#
require 'test_helper'

class InspectionPointTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  DISEASES    = %w[Fusarium Mouche Pythium Rhizoctonia Sclérotinia].freeze
  DEFORMITIES = [
    'Gel',
    'Défaut',
    'Éclatement',
    'Forme tordue',
    'Carotte ligneuse',
    'Problème de conicité',
    'Problème de coloration',
    'Déformation par nématodes'
  ].freeze

  setup do
    @activity = Activity.create!(
      name: 'InspectionTestActivity',
      nature: 'main',
      description: '',
      family: 'plant_farming',
      cultivation_variety: 'daucus_carota',

      with_cultivation: true,
      with_supports: true,
      support_variety: 'land_parcel',
      size_unit_name: 'hectare',
      size_indicator_name: 'net_surface_area',

      suspended: false,
      production_cycle: 'annual',
      production_campaign: 'at_cycle_end',
      production_system_name: 'intensive_farming',

      use_countings: true,
      use_seasons: false,
      use_tactics: false,

      # Here be what we're actually interested by.
      use_gradings: true,
      measure_grading_items_count: true,
      measure_grading_net_mass: true,
      grading_net_mass_unit_name: 'kilogram',
      measure_grading_sizes: true,
      grading_sizes_indicator_name: 'length',
      grading_sizes_unit_name: 'centimeter'
    )

    {
      disease: DISEASES,
      deformity: DEFORMITIES
    }.each do |category, p_names|
      p_names.each do |p_name|
        @activity.inspection_point_natures.create!(category: category, name: p_name)
      end
    end

    @variant = ProductNatureVariant.import_from_nomenclature(:carrot_crop)

    @plant = @variant.products.create!(
      type: 'Plant',
      name: 'DOUCH Carotte Napoli',
      variety: 'daucus',
      number: 'P00000001184',
      initial_population: 0.0,
      initial_shape: Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.884541571140289 44.3063013339422,-0.88527113199234 44.3066564276896,-0.886043608188629 44.3070364715909,-0.88676780462265 44.3074011578695,-0.88664710521698 44.3075815807696,-0.886537134647369 44.307767761266,-0.886322557926178 44.3081420398584,-0.88590145111084 44.3087101710069,-0.883626937866211 44.3080806199454,-0.883047580718994 44.3081420398584,-0.883798599243164 44.3060422101222,-0.884541571140289 44.3063013339422)))')
    )

    @inspection = @activity.inspections.create!(
      product_id: @plant.id,
      sampled_at: Time.zone.now,
      implanter_rows_number: 4,
      implanter_working_width: 0.5125,
      comment: '',
      implanter_application_width: 2.05,
      sampling_distance: 3,
      product_net_surface_area_value: 5,
      product_net_surface_area_unit: 'hectare'
    )

    @nature = @activity.inspection_point_natures.first
  end

  test 'point properly stores items_count value' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      items_count_value: 5
    )

    assert_equal 5, point.quantity_value(:items_count)
  end

  test 'point properly stores net_mass value' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      net_mass_value: 7
    )

    assert_equal 7, point.quantity_value(:net_mass)
  end

  test 'point value in dimension that\'s not available is 0' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      net_mass_value: 7
    )

    assert_equal 0, point.quantity_value(:items_count)

    point = @inspection.points.create!(
      nature_id: @nature.id,
      items_count_value: 7
    )

    assert_equal 0, point.quantity_value(:net_mass)
  end

  test 'point properly stores extremum values' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      minimal_size_value: 3,
      maximal_size_value: 9
    )
    unit = point.grading_sizes_unit

    assert_equal 3.in(unit), point.extremum_size(:min)
    assert_equal 9.in(unit), point.extremum_size(:max)
  end

  test 'projected total is accurately calculated' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      net_mass_value: 0.3075,
      items_count_value: 2
    )

    assert_equal 10_000, point.projected_total(:net_mass).to_d

    assert_in_delta 65_040.650.in(point.quantity_unit(:items_count)).to_d,
                    point.projected_total(:items_count).to_d
  end

  test 'quantity_in_unit is in an appropriate unit' do
    point = @inspection.points.create!(
      nature_id: @nature.id
    )

    assert_kind_of Measure, point.quantity_in_unit(:items_count)
    assert_match(/none/, point.quantity_in_unit(:items_count).dimension)

    assert_kind_of Measure, point.quantity_in_unit(:net_mass)
    assert_match(/mass/, point.quantity_in_unit(:net_mass).dimension)
  end

  test 'yield is correctly calculated' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      net_mass_value: 1
    )

    assert_in_delta 6_504.065.in(point.quantity_unit(:net_mass)).to_d,
                    point.quantity_yield(:net_mass).to_d
  end

  test 'percentage is correctly computed' do
    @activity.inspection_calibration_scales.create!(
      size_indicator_name: 'diameter',
      size_unit_name: 'millimeter'
    )

    c_nature = @activity.inspection_calibration_scales.first.natures.create!(
      marketable: true,
      minimal_value: 20,
      maximal_value: 30
    )

    p_nature = @activity.inspection_point_natures.create!(
      category: :disease,
      name: 'inspection_point_test'
    )

    @inspection.calibrations.create!(
      nature_id: c_nature.id,
      items_count_value: 10,
      net_mass_value: 1,
      minimal_size_value: 5,
      maximal_size_value: 15
    )

    point = @inspection.points.create!(
      nature_id: p_nature.id,
      net_mass_value: 1
    )

    assert_equal 100, point.percentage(:net_mass).to_d
  end

  test 'percentage returns 0 when inspection quantity is empty' do
    point = @inspection.points.create!(
      nature_id: @nature.id,
      items_count_value: 3
    )

    assert_equal 0, point.percentage(:items_count)
  end
end
