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
  test_model_actions

  SCALES_ATTRIBUTES = [
    [false,  0,  20],
    [ true, 20,  30],
    [ true, 30,  35],
    [ true, 35,  40],
    [false, 40, 150]
  ].freeze

  POINTS_ATTRIBUTES = [
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil, 0.21, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  0.1, nil, nil],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil]
  ].freeze

  CALIBRATION_ATTRIBUTES = [
    [ 61,  0.8,   5,  15],
    [ 82, 2.32,   5,  15],
    [  2, 0.13,  15,  17],
    [nil,  nil, nil, nil],
    [nil,  nil, nil, nil]
  ].freeze

  DISEASES    = %w(Fusarium Mouche Pythium Rhizoctonia Sclérotinia).freeze
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

    @scale = @activity.inspection_calibration_scales.create!(
      size_indicator_name: 'diameter',
      size_unit_name: 'millimeter'
    )

    SCALES_ATTRIBUTES.map { |attrs| { marketable: attrs.first, minimal_value: attrs.second, maximal_value: attrs.last } }
                     .each { |nat_attr| @activity.inspection_calibration_scales.first.natures.create!(nat_attr) }

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
      initial_shape: Charta::MultiPolygon.new('SRID=4326;MULTIPOLYGON(((-0.884541571140289 44.3063013339422,-0.88527113199234 44.3066564276896,-0.886043608188629 44.3070364715909,-0.88676780462265 44.3074011578695,-0.88664710521698 44.3075815807696,-0.886537134647369 44.307767761266,-0.886322557926178 44.3081420398584,-0.88590145111084 44.3087101710069,-0.883626937866211 44.3080806199454,-0.883047580718994 44.3081420398584,-0.883798599243164 44.3060422101222,-0.884541571140289 44.3063013339422)))')
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

    CALIBRATION_ATTRIBUTES.each_with_index do |c_attrs, i|
      @inspection.calibrations.create!(
        nature_id: @scale.natures.order(:id)[i].id,
        items_count_value: c_attrs[0],
        net_mass_value: c_attrs[1],
        minimal_size_value: c_attrs[2],
        maximal_size_value: c_attrs[3]
      )
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

  test 'population gets updated on move!' do
    assert true
  end
end
