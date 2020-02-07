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
# == Table: plant_countings
#
#  average_value                :decimal(19, 4)
#  comment                      :text
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  id                           :integer          not null, primary key
#  lock_version                 :integer          default(0), not null
#  nature                       :string
#  number                       :string
#  plant_density_abacus_id      :integer          not null
#  plant_density_abacus_item_id :integer          not null
#  plant_id                     :integer          not null
#  read_at                      :datetime
#  rows_count_value             :integer
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  working_width_value          :decimal(19, 4)
#
require 'test_helper'

class PlantCountingTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  ABACI_ITEM_ATTRIBUTES = [
    [1.2, 70],
    [1.25, 72],
    [1.3, 75],
    [1.35, 78],
    [1.4, 81],
    [1.45, 84],
    [1.4, 87],
    [1.45, 90],
    [1.4, 92],
    [1.45, 95],
    [1.7, 98]
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

      use_countings: true
    )

    @abacus = @activity.plant_density_abaci.create!(
      name: 'Carotte - 3 rangs',
      seeding_density_unit: 'million_per_hectare',
      sampling_length_unit: 'meter',
      germination_percentage: 80
    )

    ABACI_ITEM_ATTRIBUTES.each do |abacus_item|
      @abacus.items.create!(
        seeding_density_value: abacus_item.first,
        plants_count: abacus_item.last
      )
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
  end

  test 'countings use their plant\'s sower\'s readings to do the calculations when not overridden' do
    plant = sow_plant
    counting = new_counting plant: plant

    assert_equal 4, counting.rows_count
    assert_equal 20.5.in(:meter), counting.indicator_working_width
  end

  test 'sower-related data methods raise errors when plant hasn\'t been sowed and data isn\'t filled out' do
    counting = new_counting # No data + No sower
    assert_raises { counting.implanter_working_width }
    assert_raises { counting.rows_count              }

    counting = new_counting rows_count_value: 4, working_width_value: 2.05
    assert_nothing_raised { counting.implanter_working_width }
    assert_nothing_raised { counting.rows_count              }

    plant = sow_plant
    counting = new_counting plant: plant
    assert_nothing_raised { counting.implanter_working_width }
    assert_nothing_raised { counting.rows_count              }
  end

  test 'expected_seeding_density is correctly computed' do
    counting_at_sowing = new_counting nature: :sowing
    assert_equal 1.2, counting_at_sowing.expected_seeding_density.to_f

    counting_at_germination = new_counting nature: :germination
    assert_equal 1.2 * 0.8, counting_at_germination.expected_seeding_density.to_f
  end

  test 'density_computable? returns false when required data is unavailable, true when it is' do
    counting = new_counting
    refute counting.density_computable? # No sower

    plant = sow_plant
    counting.update!(plant_id: plant.id)
    counting.reload
    assert counting.density_computable?
  end

  test 'values_expected? should be computed correctly when at sowing' do
    plant = sow_plant
    ok_counting = new_counting plant: plant, nature: :sowing, item_values: [73, 70, 65, 66, 75]
    assert ok_counting.values_expected?

    wrong_counting = new_counting plant: plant, nature: :sowing, item_values: [54, 49, 58, 52]
    refute wrong_counting.values_expected?
  end

  test 'values_expected? should be computed correctly when at germination' do
    plant = sow_plant
    wrong_counting = new_counting plant: plant, nature: :germination, item_values: [73, 70, 65, 66, 75]
    refute wrong_counting.values_expected?

    ok_counting = new_counting plant: plant, nature: :germination, item_values: [54, 49, 58, 52]
    assert ok_counting.values_expected?
  end

  test 'status lights should be appropriate for values' do
    plant = sow_plant
    ok_counting = new_counting plant: plant, item_values: [73, 70, 65, 66, 75]
    assert_match(/go/, ok_counting.status)

    wrong_counting = new_counting plant: plant, item_values: [41, 52, 47, 11]
    assert_match(/stop/, wrong_counting.status)
  end

  test 'average is zero when no items are present' do
    counting = new_counting
    assert_equal 0, counting.average_value
  end

  test 'average is computed from items' do
    counting = new_counting item_values: [1]
    assert_equal 1, counting.average_value

    counting.items.create!(value: 2)
    assert_equal 1.5, counting.average_value

    counting.items.create!(value: 3)
    assert_equal 2, counting.average_value
  end

  test 'average is updated when items are updated' do
    counting = new_counting item_values: [1, 2, 3]
    counting.items.find_by(value: 1).update!(value: 4)

    assert_equal 3, counting.average_value
  end

  protected

  def new_counting(nature: :sowing, plant: nil, working_width_value: nil, rows_count_value: nil, plant_density_abacus: nil, plant_density_abacus_item: nil, average_value: nil, item_values: [])
    plant_density_abacus      ||= @abacus
    plant_density_abacus_item ||= @abacus.items.order(:seeding_density_value).first
    plant ||= @plant
    plant.plant_countings.create!(
      nature: nature,
      plant_density_abacus_id: plant_density_abacus.id,
      plant_density_abacus_item_id: plant_density_abacus_item.id,
      average_value: average_value,
      working_width_value: working_width_value,
      rows_count_value: rows_count_value,
      items_attributes: item_values.map { |item_value| { value: item_value } }
    )
  end

  def sow_plant
    category = ProductNatureCategory.create!(
      name: 'ÉquipementInspectionTest',
      number: '00000024',
      reference_name: 'equipment',
      pictogram: 'tractor',
      type: 'VariantCategories::EquipmentCategory'
    )

    nature = ProductNature.create!(
      name: 'SemoirInspectionTest',
      number: '00000058',
      variety: 'trailed_equipment',
      reference_name: 'sower',
      abilities_list: ['sow'],
      population_counting: 'unitary',
      variable_indicators_list: [:geolocation],
      frozen_indicators_list: %i[nominal_storable_net_volume application_width rows_count theoretical_working_speed],
      type: 'VariantTypes::EquipmentType'
    )

    variant = ProductNatureVariant.create!(
      category_id: category.id,
      nature_id: nature.id,
      name: 'SemoirInspectionTest',
      work_number: nil,
      variety: 'trailed_equipment',
      derivative_of: nil,
      reference_name: 'sower',
      unit_name: 'Équipement',
      type: 'Variants::EquipmentVariant'
    )

    variant.readings.create!(
      indicator_name: 'rows_count',
      indicator_datatype: 'integer',
      integer_value: 4
    )

    variant.readings.create!(
      indicator_name: 'application_width',
      indicator_datatype: 'measure',
      absolute_measure_value_value: 2.05,
      absolute_measure_value_unit: 'meter',
      measure_value_value: 2.05E1,
      measure_value_unit: 'meter'
    )

    equipment = variant.products.create!(
      type: 'Equipment',
      name: 'Semoir Agricola neuf',
      number: 'P00000000087',
      initial_population: 0.0,
      variety: 'trailed_equipment',
      born_at: Time.zone.now
    )

    intervention = Intervention.create!(
      procedure_name: 'sowing',
      state: 'done',
      number: '50',
      nature: 'record',
      working_periods: fake_working_periods
    )

    intervention.outputs.create!(
      quantity_population: @plant.net_surface_area,
      variant_id: @variant.id,
      reference_name: 'plant',
      position: 3
    )

    intervention.tools.create!(
      product_id: equipment.id,
      reference_name: 'sower',
      position: 5
    )

    intervention.outputs.first.product
  end

  def fake_working_periods
    now = Time.zone.parse('2018-1-1 00:00:00')
    [
      InterventionWorkingPeriod.new(started_at: now - 3.hours, stopped_at: now - 2.hours, nature: 'preparation'),
      InterventionWorkingPeriod.new(started_at: now - 2.hours, stopped_at: now - 90.minutes, nature: 'travel'),
      InterventionWorkingPeriod.new(started_at: now - 90.minutes, stopped_at: now - 30.minutes, nature: 'intervention'),
      InterventionWorkingPeriod.new(started_at: now - 30.minutes, stopped_at: now, nature: 'travel')
    ]
  end
end
