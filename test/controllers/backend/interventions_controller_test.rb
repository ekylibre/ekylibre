require 'test_helper'

module Backend
  class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions set: :show, except: %i[validate_harvest_delay validate_reentry_delay run change_state change_page compute unroll purchase sell modal purchase_order_items compare_realised_with_planned create_duplicate_intervention]
    # , compute: { mode: create params: { format: json } }
    # TODO: Re-activate #compute, #change_state, #unroll, #purchase, #sell,
    # #modal, #change_page and #purchase_order_items test

    setup do
      user = create(:user)
      sign_in(user)
    end

    test 'change state action with no params should return error' do
      params = {}
      assert_raises ActionController::ParameterMissing do
        post :change_state, params
      end
    end

    test 'change state action from request intervention to in_progress intervention should create new intervention with same parameters' do
      # Following intervention gets 1 group parameter (containing 1 target + 1 output) and 1 input
      request_intervention = create(:sowing_intervention_with_all_parameters, nature: :request)
      params = { intervention: { interventions_ids: [request_intervention.id].to_json, state: :in_progress }}
      assert_empty request_intervention.record_interventions
      post :change_state, params
      record_intervention = request_intervention.record_interventions.last
      assert_not_nil record_intervention

      # Group parameter
      request_gp = request_intervention.group_parameters.last
      record_gp = record_intervention.group_parameters.last
      assert_not_nil request_gp
      assert_not_nil record_gp

      # Targets
      assert_equal request_gp.targets.count, record_gp.targets.count
      assert_equal request_gp.targets.last.product_id, record_gp.targets.last.product_id

      # Outputs
      assert_equal request_gp.outputs.count, record_gp.outputs.count
      assert_equal request_gp.outputs.last.product_id, record_gp.outputs.last.product_id
      assert_equal request_gp.outputs.last.quantity_population, record_gp.outputs.last.quantity_population

      # Inputs
      request_inputs = request_intervention.inputs
      record_inputs = record_intervention.inputs
      assert_equal request_inputs.count, record_inputs.count
      assert_equal request_inputs.last.product_id, record_inputs.last.product_id
      assert_equal request_inputs.last.quantity_value, record_inputs.last.quantity_value
      assert_equal request_inputs.last.quantity_handler, record_inputs.last.quantity_handler

      assert_redirected_to backend_intervention_path(record_intervention)
    end
  end
end
