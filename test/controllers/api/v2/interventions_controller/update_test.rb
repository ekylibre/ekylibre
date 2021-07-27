require 'test_helper'
require 'ffaker'

module Api
  module V2
    class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test 'update with hoeing intervention (with targets/equipments/workers)' do
        land_parcel = create(:land_parcel, born_at: "2017-06-01T00:00:00Z")
        worker1 = create(:worker)
        worker2 = create(:worker)
        driver = create(:worker)
        tractor = create(:equipment)
        hoe = create(:equipment)
        intervention = create(:sowing_intervention_with_all_parameters)

        description = 'Hoeing intervention'

        params = { id: intervention.id,
                   procedure_name: 'hoeing',
                   description: description,
                   actions: ['weeding'],
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
        put :update, params: params
        assert_response :ok
        id = json_response['id']
        intervention = Intervention.find(id)
        assert ([driver.id, worker1.id, worker2.id] - intervention.doers.pluck(:product_id)).empty?
        assert ([tractor.id, hoe.id].sort - intervention.tools.pluck(:product_id).sort).empty?
        assert intervention.targets.pluck(:product_id).include?(land_parcel.id)
        assert_equal description, intervention.description
      end

      test 'return errors message and status bad_request if params are invalids' do
        intervention = create(:sowing_intervention_with_all_parameters)
        params = { id: intervention.id,
                   working_periods_attributes: [
                      { started_at: '01/07/0000 12:00'.to_datetime }
                    ],  }
        put :update, params: params
        assert_response :forbidden
        assert json_response['errors'].any?
      end

      test 'Nested attributes can be destroyed' do
        intervention = create(:sowing_intervention_with_all_parameters)
        group_parameter = intervention.group_parameters.first
        params = {
          id: intervention.id,
          group_parameters_attributes: [
            {
              id: group_parameter.id,
              reference_name: 'zone',
              targets_attributes: [
                { id: group_parameter.targets.first.id, _destroy: "1" }
              ]

            }
          ],
          doers_attributes: [
            {
              id: intervention.doers.first.id, _destroy: "1"
            }
          ]
        }
        put :update, params: params
        assert_equal 0, intervention.reload.doers.count
        assert_equal 0, intervention.reload.group_parameters.first.targets.count
      end

      test 'Nested group can be destroyed' do
        intervention = create(:sowing_intervention_with_all_parameters)
        params = {
          id: intervention.id,
          group_parameters_attributes: [
            {
              id: intervention.group_parameters.first.id,
              reference_name: 'zone',
              _destroy: "1"
            }
          ],
        }
        put :update, params: params
        assert_equal 0, intervention.reload.group_parameters.count
      end
    end
  end
end
