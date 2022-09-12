require 'test_helper'

module Backend
  class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions set: :show, except: %i[link_rides_to_planned validate_harvest_delay validate_reentry_delay run change_state change_page compute unroll purchase sell modal purchase_order_items compare_realised_with_planned create_duplicate_intervention export]
    # , compute: { mode: create params: { format: json } }
    # TODO: Re-activate #compute, #change_state, #unroll, #purchase, #sell,
    # #modal, #change_page and #purchase_order_items test

    setup do
      @user = create(:user)
      sign_in(@user)
    end

    test '#link_rides_to_planned' do
      intervention = create(:intervention, nature: :request)
      ride = create(:ride)
      mock= MiniTest::Mock.new
      mock.expect(:call, nil, [intervention, [ride], { perform_as: @user }])
      ::Interventions::LinkRidesToPlannedJob.stub(:perform_later, mock) do
        put :link_rides_to_planned, xhr: true, params: { id: intervention.id, ride_ids: [ride.id] }
      end
      mock.verify
      assert_response :ok
    end

    test 'sowing intervention : #change_state action from request intervention to in_progress intervention should create new intervention with same parameters' do
      # Following intervention gets 1 group parameter (containing 1 target + 1 output) and 1 input
      request_intervention = create(:sowing_intervention_with_all_parameters, nature: :request)
      params = { intervention: { interventions_ids: [request_intervention.id].to_json, state: :in_progress } }
      assert_empty request_intervention.record_interventions
      post :change_state, params: params
      record_intervention = request_intervention.record_interventions.last
      assert_not_nil record_intervention
      request_gp = request_intervention.group_parameters.last
      record_gp = record_intervention.group_parameters.last
      assert_equal request_gp.outputs.last.product, record_gp.outputs.last.product, 'The product output remains the same'
      assert_redirected_to backend_intervention_path(record_intervention)
    end

    test '#change_state action with no params should return error' do
      params = {}
      assert_raises ActionController::ParameterMissing do
        post :change_state, params: params
      end
    end

    test '#change_state action with redirect false, redirect back' do
      request_intervention = create(:sowing_intervention_with_all_parameters, nature: :request)
      params = { intervention: { interventions_ids: [request_intervention.id].to_json, state: :in_progress, redirect: false } }
      request.env["HTTP_REFERER"] = "where_i_came_from"
      post :change_state, params: params
      assert_redirected_to "where_i_came_from"
    end
  end
end
