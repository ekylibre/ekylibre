require 'test_helper'
require 'ffaker'

module Api
  module V2
    class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      setup do
        @provider = { vendor: 'ekylibre',
          name: 'zero',
          id: 0,
          data: { zero_id: 5 } }
      end

      attr_reader :provider

      test 'create hoeing intervention (with targets/equipments/workers)' do
        land_parcel = create(:land_parcel, born_at: "2019-01-01T00:00:00Z")
        worker1 = create(:worker)
        worker2 = create(:worker)
        driver = create(:worker)
        tractor = create(:equipment)
        hoe = create(:equipment)
        params = { procedure_name: 'hoeing',
                   provider: provider,
                   working_periods_attributes: [
                     { started_at: '01/01/2019 12:00'.to_datetime,
                       stopped_at: '01/01/2019 13:30'.to_datetime }
],
                   targets_attributes: [
                     { product_id: land_parcel.id, reference_name: 'land_parcel' }
                   ],
                   doers_attributes: [
                     { product_id: worker1.id, reference_name: 'doer' },
                     { product_id: worker2.id, reference_name: 'doer' },
                     { product_id: driver.id, reference_name: 'driver' }
                   ],
                   tools_attributes: [
                     { product_id: tractor.id, reference_name: 'tractor' },
                     { product_id: hoe.id, reference_name: 'hoe' },
                   ] }
        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 1, intervention.targets.count
        assert_equal 3, intervention.doers.count
        assert_equal 2, intervention.tools.count
      end

      test 'create fertilizing intervention (with inputs)' do
        authorize_user(@admin_user)

        input_product = create(:fertilizer_product)
        input_product.variant.read!(:net_mass, '4 kilogram')
        params = { procedure_name: 'fertilizing',
                   provider: provider,
                   working_periods_attributes: [
                     { started_at: '01/01/2019 12:00'.to_datetime,
                       stopped_at: '01/01/2019 13:30'.to_datetime }
                   ],
                   inputs_attributes: [
                     {
                       product_id: input_product.id,
                       quantity_value: 5000,
                       quantity_population: 5,
                       quantity_handler: 'net_mass',
                       reference_name: 'fertilizer'
                     }
                   ] }

        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 1, intervention.inputs.count
      end

      test 'create harvesting intervention (with outputs)' do
        variant = create(:harvest_variant)
        variant.read!(:net_mass, '2 kilogram')
        plant = create(:corn_plant, born_at: "2019-01-01T00:00:00Z")
        params = { procedure_name: 'harvesting',
                   provider: provider,
                   working_periods_attributes: [
                     { started_at: '01/01/2019 12:00'.to_datetime,
                       stopped_at: '01/01/2019 13:30'.to_datetime }
                   ],
                   targets_attributes: [{
                                          product_id: plant.id,
                                          reference_name: 'plant'
                                        }],
                   outputs_attributes: [
                     {
                       variant_id: variant.id,
                       quantity_value: 5000,
                       quantity_population: 5,
                       quantity_handler: 'net_mass',
                       reference_name: 'matters'
                     }
                   ] }

        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 1, intervention.outputs.count
      end

      test 'create sowing intervention (with group parameters)' do
        land_parcel1 = create(:land_parcel)
        land_parcel2 = create(:land_parcel)
        variant = create(:product_nature_variant)
        product = create(:seed_product)
        product.variant.read!(:net_mass, '2000 kilogram')
        params = {
          procedure_name: 'sowing',
          provider: provider,
          working_periods_attributes: [
            {
              started_at: "2017-11-06 10:04:39",
              stopped_at: "2017-11-06 12:04:39"
            }
          ],
          group_parameters_attributes: [
            {
              reference_name: 'zone',
              targets_attributes: [
                {
                  product_id: land_parcel1.id,
                  reference_name: 'land_parcel'
                }
              ],
              outputs_attributes: [
                {
                  variant_id: variant.id,
                  reference_name: 'plant',
                  specie_variety_name: 'test',
                  batch_number: 'test2'
                }
              ]
            },
            {
              reference_name: 'zone',
              targets_attributes: [
                {
                  product_id: land_parcel2.id,
                  reference_name: 'land_parcel'
                }
              ],
              outputs_attributes: [
                {
                  variant_id: variant.id,
                  reference_name: 'plant',
                  specie_variety_name: 'test',
                  batch_number: 'test2'
                }
              ]
            }
          ],
          inputs_attributes: [
            {
              product_id: product.id,
              quantity_value: 3,
              quantity_handler: 'net_mass',
              reference_name: 'seeds'
            }
          ]
        }
        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 2, intervention.group_parameters.count
        assert_equal 2, intervention.outputs.count
        assert_equal 'test', intervention.outputs.last.specie_variety_name
        assert_equal 'test2', intervention.outputs.last.batch_number
      end

      test 'create fertilizing intervention (with readings on tools)' do
        input_product = create(:fertilizer_product, initial_born_at: "2019-01-01T00:00:00Z")
        input_product.variant.read!(:net_mass, '4 kilogram')
        tractor1 = create(:tractor)
        tractor2 = create(:tractor)
        tractor3 = create(:tractor)
        params = {
          procedure_name: 'fertilizing',
          provider: provider,
          working_periods_attributes: [
            { started_at: '01/01/2019 12:00'.to_datetime,
              stopped_at: '01/01/2019 13:30'.to_datetime }
          ],
          inputs_attributes: [
            {
              product_id: input_product.id,
              quantity_value: 5000,
              quantity_handler: 'net_mass',
              reference_name: 'fertilizer'
            }
          ],
          tools_attributes: [
            {
              product_id: tractor1.id,
              reference_name: "tractor",
              readings_attributes: [
                {
                  indicator_name: "hour_counter",
                  measure_value_value: "8",
                  measure_value_unit: "hour"
                }
              ]
            },
            {
              product_id: tractor2.id,
              reference_name: "tractor"
            },
            {
              product_id: tractor3.id,
              reference_name: "tractor",
              readings_attributes: [
                {
                  indicator_name: "hour_counter",
                  measure_value_value: "5",
                  measure_value_unit: "hour"
                }
              ]
            }
          ]
        }

        post :create, params: params
        assert_response :created

        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 3, intervention.tools.count
        assert_equal [], intervention.procedure.parameters.flat_map(&:readings)

        tool1_reading = intervention.tools.find_by(product_id: tractor1.id).readings.first
        tool2_reading = intervention.tools.find_by(product_id: tractor3.id).readings.first
        assert_equal tool1_reading.value, Measure.new(8, :hour)
        assert_equal tool2_reading.value, Measure.new(5, :hour)
      end

      test 'equipment_maintenance intervention with readings on target' do
        tractor1 = create(:tractor)
        tractor2 = create(:tractor)
        tractor3 = create(:tractor)
        equipment = create(:equipment)
        params = {
          provider: provider,
          procedure_name: 'equipment_maintenance',
          actions: [
            "curative_maintenance"
          ],
          working_periods_attributes: [
            {
              started_at: "2019-11-06 10:04:39",
              stopped_at: "2019-11-06 11:04:39"
            }
          ],
          group_parameters_attributes: [
            {
              reference_name: "work",
              targets_attributes: [
                {
                  product_id: tractor1.id,
                  reference_name: "equipment",
                  readings_attributes: [
                    {
                      indicator_name: "hour_counter",
                      measure_value_value: 23,
                      measure_value_unit: "hour"
                    }
                  ]
                }
              ],
              inputs_attributes: [
                {
                  product_id: equipment.id,
                  reference_name: "replacement_part",
                  quantity_value: 1,
                  quantity_handler: "population"
                }
              ]
            },
            {
              reference_name: "work",
              targets_attributes: [
                {
                  product_id: tractor2,
                  reference_name: "equipment"
                }
              ]
            },
            {
              reference_name: "work",
              targets_attributes: [
                {
                  product_id: tractor3,
                  reference_name: "equipment",
                  readings_attributes: [
                    {
                      indicator_name: "hour_counter",
                      measure_value_value: 15,
                      measure_value_unit: "hour"
                    }
                  ]
                }
              ]
            }
          ]
        }
        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal [], intervention.procedure.product_parameters.flat_map(&:readings)
        target_reading1 = intervention.targets.find_by(product_id: tractor1.id).readings.first
        assert_equal target_reading1.value, Measure.new(23, :hour)
        assert_equal intervention.targets.find_by(product_id: tractor2.id).readings, []
        target_reading3 = intervention.targets.find_by(product_id: tractor3.id).readings.first
        assert_equal target_reading3.value, Measure.new(15, :hour)
      end
    end
  end
end
