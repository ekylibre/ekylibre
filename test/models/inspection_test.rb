# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  forecast_harvest_week          :integer
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
  test_model_actions

  SCALES_ATTRIBUTES = [
    %i[diameter millimeter],
    %i[height centimeter]
  ].freeze

  SCALE_NATURES_ATTRIBUTES = [
    [
      [false, 0, 20],
      [true, 20,  30],
      [true, 30,  35],
      [true, 35,  40],
      [false, 40, 150]
    ],
    [
      [false, 15, 25],
      [true, 25, 35],
      [false, 35, 45]
    ]
  ].freeze

  POINTS_ATTRIBUTES = [
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [3, 0.21, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [1, 0.1, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil]
  ].freeze

  CALIBRATION_ATTRIBUTES = [
    [
      [61, 0.8,   5, 15],
      [82, 2.32, 5, 15],
      [2, 0.13, 15, 17],
      [nil,  nil, nil, nil],
      [nil,  nil, nil, nil]
    ],
    [
      [4,    1, nil, nil],
      [9,    1, nil, nil],
      [10,   2, nil, nil]
    ]
  ].freeze

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

    @scales = SCALES_ATTRIBUTES.map { |attrs| { size_indicator_name: attrs.first, size_unit_name: attrs.last } }
                               .map { |s_attrs| @activity.inspection_calibration_scales.create!(s_attrs) }

    SCALE_NATURES_ATTRIBUTES.each_with_index do |n_vals, index|
      n_vals.map { |attrs| { marketable: attrs.first, minimal_value: attrs.second, maximal_value: attrs.last } }
            .each { |nat_attr| @activity.inspection_calibration_scales[index].natures.create!(nat_attr) }
    end

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
      born_at: Time.zone.now - 1.day,
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

    CALIBRATION_ATTRIBUTES.each_with_index do |n_vals, index|
      n_vals.each_with_index do |c_attrs, i|
        @inspection.calibrations.create!(
          nature_id: @scales[index].natures.order(:id)[i].id,
          items_count_value: c_attrs[0],
          net_mass_value: c_attrs[1],
          minimal_size_value: c_attrs[2],
          maximal_size_value: c_attrs[3]
        )
      end
    end

    POINTS_ATTRIBUTES.each_with_index do |p_attrs, i|
      @inspection.points.create!(
        nature_id: @activity.inspection_point_natures.order(:id)[i - 1].id,
        items_count_value: p_attrs[0],
        net_mass_value: p_attrs[1],
        minimal_size_value: p_attrs[2],
        maximal_size_value: p_attrs[3]
      )
    end
  end

  test 'position is correctly computed' do
    assert_equal 1, @inspection.position

    inspection = @activity.inspections.create!(
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

    assert_equal 2, inspection.position
  end

  %i[items_count net_mass].each do |dimension|
    test "#{dimension} - quantity is correctly computed" do
      expected = { items_count: 84.in(:unity), net_mass: 3.625.in(:kilogram) }

      assert_equal expected[dimension].unit, @inspection.quantity(dimension).unit
      assert_in_delta expected[dimension].to_d, @inspection.quantity(dimension).to_d
    end

    test "#{dimension} - quantity yield is correctly computed" do
      expected = { items_count: 546_341.4634100406.in(:unity_per_hectare), net_mass: 23_577.235772357722.in(:kilogram_per_hectare) }

      assert_equal expected[dimension].unit, @inspection.quantity_yield(dimension).unit
      assert_in_delta expected[dimension].to_d, @inspection.quantity_yield(dimension).to_d
    end

    test "#{dimension} - marketable quantity is correctly computed" do
      expected = { items_count: 1_440_185.830429733.in(:unity), net_mass: 51_300.25231286796.in(:kilogram) }

      assert_equal expected[dimension].unit, @inspection.marketable_quantity(dimension).unit
      assert_in_delta expected[dimension].to_d, @inspection.marketable_quantity(dimension).to_d
    end

    test "#{dimension} - marketable yield is correctly computed" do
      expected = { items_count: 288_037.1660859464.in(:unity_per_hectare), net_mass: 10_260.050462573454.in(:kilogram_per_hectare) }

      assert_equal expected[dimension].unit, @inspection.marketable_yield(dimension).unit
      assert_in_delta expected[dimension].to_d, @inspection.marketable_yield(dimension).to_d
    end

    test "#{dimension} - projected total is correctly computed" do
      expected = { items_count: 2_731_707.317073171.in(:unity), net_mass: 117_886.17886178862.in(:kilogram) }

      assert_equal expected[dimension].unit, @inspection.projected_total(dimension).unit
      assert_in_delta expected[dimension].to_d, @inspection.projected_total(dimension).to_d
    end

    test "#{dimension} - unmarketable rate is correctly computed" do
      expected = { items_count: 4.762, net_mass: 8.552 }

      assert_in_delta expected[dimension], @inspection.unmarketable_rate(dimension) * 100
    end
  end
end
