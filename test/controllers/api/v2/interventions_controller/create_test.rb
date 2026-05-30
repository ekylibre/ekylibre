require 'test_helper'
require 'ffaker'

module Api
  module V2
    class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      setup do
        @request.headers['CONTENT_TYPE'] = "application/json"
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
        # create a fertilizer with conditionning of 1 kilogram unit
        input_product = create(:fertilizer_product, born_at: "2019-01-01T00:00:00Z")
        input_product.read!(:net_mass, '1 kilogram', at: "2019-01-01T00:00:00Z")
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
                       quantity_unit_name: 'kilogram',
                       quantity_population: 5000,
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
        variant = create(:plant_variant)
        # create a seed with conditionning of 1 ton unit
        product = create(:seed_product, born_at: "2017-11-01T00:00:00Z")
        product.variant.read!(:net_mass, '1 kilogram')
        product.read!(:net_mass, '1000 kilogram', at: "2017-11-01T00:00:00Z")
        params = {
          procedure_name: 'sowing',
          provider: provider,
          working_periods_attributes: [
            {
              started_at: "2017-11-06 10:04:39",
              stopped_at: "2017-11-06 12:04:39"
            }
          ],
          inputs_attributes: [
            {
              product_id: product.id,
              quantity_value: 2000,
              quantity_unit_name: 'kilogram',
              quantity_indicator_name: 'net_mass',
              quantity_population: 2,
              quantity_handler: 'net_mass',
              reference_name: 'seeds'
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
            # {
            #   reference_name: 'zone',
            #   targets_attributes: [
            #     {
            #       product_id: land_parcel2.id,
            #       reference_name: 'land_parcel'
            #     }
            #   ],
            #   outputs_attributes: [
            #     {
            #       variant_id: variant.id,
            #       reference_name: 'plant',
            #       specie_variety_name: 'test',
            #       batch_number: 'test3'
            #     }
            #   ]
            # },
          ]
        }
        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 1, intervention.group_parameters.count
        assert_equal 1, intervention.outputs.count
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
                  product_id: tractor2.id,
                  reference_name: "equipment"
                }
              ]
            },
            {
              reference_name: "work",
              targets_attributes: [
                {
                  product_id: tractor3.id,
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

      test 'create parturition intervention' do
        mammalia = Animal.find(5)
        worker1 = Worker.find(79)
        params ={ procedure_name: 'parturition',
                  provider: provider,
                  group_parameters_attributes: [
                    {
                      reference_name: 'parturition',
                      targets_attributes: [
                        {
                          product_id: mammalia.id,
                          reference_name: 'mother'
                        }
                      ],
                      outputs_attributes: [
                        {
                          variant_id: mammalia.variant_id,
                          quantity_population: 1,
                          reference_name: "child",
                          new_name: 'nouveau nom',
                          identification_number: 1000,
                          readings_attributes: [
                            {
                              indicator_name: "net_mass",
                              measure_value_value: 250,
                              measure_value_unit: "kilogram"
                            },
                            {
                              indicator_name: "sex",
                              choice_value: "female"
                            },
                            {
                              indicator_name: "mammalia_birth_condition",
                              choice_value: "without_help"
                            },
                            {
                              indicator_name: "healthy",
                              boolean_value: true
                            }
                          ]
                        }
                      ]
                    }
                  ],
                  working_periods_attributes: [
                    { started_at: '01/01/2019 12:00'.to_datetime,
                      stopped_at: '01/01/2019 13:30'.to_datetime }
                  ],
                  doers_attributes: [
                    { product_id: worker1.id, reference_name: 'caregiver' }
                  ],  }
        post :create, params: params
        assert_response :created
        id = json_response['id']
        intervention = Intervention.find(id)
        assert_equal 1, intervention.targets.count
        assert_equal 1, intervention.outputs.count
        output = intervention.outputs.first
        assert_equal 4, output.readings.count
      end

      # Regression: issue #2660 — provider deduplication / persistence
      test 'create persists the provider block on the intervention' do
        land_parcel = create(:land_parcel, born_at: "2019-01-01T00:00:00Z")
        worker = create(:worker)
        uuid = '11111111-1111-4111-8111-111111111111'
        params = base_hoeing_params(land_parcel, worker, provider.merge(id: uuid))

        post :create, params: params
        assert_response :created

        intervention = Intervention.find(json_response['id'])
        assert_equal 'ekylibre', intervention.provider_vendor
        assert_equal 'zero', intervention.provider_name
        assert_equal uuid, intervention.provider_id
        assert_equal({ zero_id: 5 }, intervention.provider_data)
      end

      test 'create is idempotent on identical provider id (no duplicate)' do
        land_parcel = create(:land_parcel, born_at: "2019-01-01T00:00:00Z")
        worker = create(:worker)
        uuid = '22222222-2222-4222-8222-222222222222'
        params = base_hoeing_params(land_parcel, worker, provider.merge(id: uuid))

        post :create, params: params
        assert_response :created
        first_id = json_response['id']

        assert_no_difference -> { Intervention.of_provider_id(uuid).count } do
          post :create, params: params
        end
        assert_response :ok
        assert_equal first_id, json_response['id']
      end

      test 'index exposes provider and filters by provider_id' do
        land_parcel = create(:land_parcel, born_at: "2019-01-01T00:00:00Z")
        worker = create(:worker)
        uuid = '33333333-3333-4333-8333-333333333333'
        post :create, params: base_hoeing_params(land_parcel, worker, provider.merge(id: uuid))
        assert_response :created
        created_id = json_response['id']

        get :index, params: { provider_id: uuid }
        assert_response :ok
        ids = json_response.map { |i| i['id'] }
        assert_includes ids, created_id
        assert json_response.all? { |i| i['provider'] && i['provider']['id'] == uuid }
      end

      # Regression: issue #2661 — a spraying intervention with targets + inputs
      # exercises the Procedo formula computation path (Division and
      # ActorPresenceTest nodes via `forward="VALUE / PRODUCT.net_mass(...)"` and
      # `if="PRODUCT?"`). A node-dispatch bug there returned 400 instead of 201.
      test 'create spraying intervention with target and input (procedo formula path)' do
        land_parcel = create(:land_parcel, born_at: "2019-01-01T00:00:00Z")
        input_product = create(:phytosanitary_product, born_at: "2019-01-01T00:00:00Z")
        input_product.read!(:net_mass, '1 kilogram', at: "2019-01-01T00:00:00Z")
        driver = create(:worker)

        params = { procedure_name: 'spraying',
                   provider: provider,
                   working_periods_attributes: [
                     { started_at: '01/01/2019 12:00'.to_datetime,
                       stopped_at: '01/01/2019 13:30'.to_datetime }
                   ],
                   targets_attributes: [
                     { product_id: land_parcel.id, reference_name: 'cultivation' }
                   ],
                   inputs_attributes: [
                     { product_id: input_product.id,
                       quantity_value: 5,
                       quantity_unit_name: 'kilogram',
                       quantity_population: 5,
                       quantity_handler: 'net_mass',
                       reference_name: 'plant_medicine' }
                   ],
                   doers_attributes: [
                     { product_id: driver.id, reference_name: 'driver' }
                   ] }

        post :create, params: params
        assert_response :created
        intervention = Intervention.find(json_response['id'])
        assert_equal 1, intervention.targets.count
        assert_equal 1, intervention.inputs.count
      end

      # Regression: issue #2660 — a spraying intervention that references a
      # `sprayer` tool. The sprayer reference declares measure readings
      # (nominal_storable_net_volume, application_width) which ComputeReadings
      # auto-seeds WITHOUT a value. Persisting such an empty measure reading
      # used to emit the `measure_value` composed_of aggregate as nil and crash
      # with `undefined method 'unit' for nil:NilClass` (=> 400). Empty readings
      # must be pruned, so this must return 201 and the sprayer must carry no
      # valueless measure readings.
      test 'create spraying intervention with sprayer tool (prunes empty measure readings)' do
        land_parcel = create(:land_parcel, born_at: "2019-01-01T00:00:00Z")
        input_product = create(:phytosanitary_product, born_at: "2019-01-01T00:00:00Z")
        input_product.read!(:net_mass, '1 kilogram', at: "2019-01-01T00:00:00Z")
        driver = create(:worker)
        sprayer = create(:equipment)

        params = { procedure_name: 'spraying',
                   provider: provider,
                   working_periods_attributes: [
                     { started_at: '01/01/2019 12:00'.to_datetime,
                       stopped_at: '01/01/2019 13:30'.to_datetime }
                   ],
                   targets_attributes: [
                     { product_id: land_parcel.id, reference_name: 'cultivation' }
                   ],
                   inputs_attributes: [
                     { product_id: input_product.id,
                       quantity_value: 5,
                       quantity_population: 5,
                       quantity_handler: 'net_mass',
                       reference_name: 'plant_medicine' }
                   ],
                   doers_attributes: [
                     { product_id: driver.id, reference_name: 'driver' }
                   ],
                   tools_attributes: [
                     { product_id: sprayer.id, reference_name: 'sprayer' }
                   ] }

        post :create, params: params
        assert_response :created
        intervention = Intervention.find(json_response['id'])
        tool = intervention.tools.find_by(reference_name: 'sprayer')
        assert tool, 'sprayer tool should be persisted'
        # Empty measure readings must have been pruned (none persisted without a value).
        assert tool.readings.none? { |r| r.indicator_datatype_measure? && r.measure_value_value.nil? },
               'no valueless measure reading should be persisted'
      end

      private

        def base_hoeing_params(land_parcel, worker, provider_block)
          { procedure_name: 'hoeing',
            provider: provider_block,
            working_periods_attributes: [
              { started_at: '01/01/2019 12:00'.to_datetime,
                stopped_at: '01/01/2019 13:30'.to_datetime }
            ],
            targets_attributes: [
              { product_id: land_parcel.id, reference_name: 'land_parcel' }
            ],
            doers_attributes: [
              { product_id: worker.id, reference_name: 'doer' }
            ] }
        end
    end
  end
end
