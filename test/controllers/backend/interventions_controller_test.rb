require 'test_helper'

module Backend
  class InterventionsControllerTest < ActionController::TestCase
    test_restfully_all_actions compute: { mode: :create, params: { format: :json } }, set: :show, except: :run

    test 'should get new' do
      get :new
      assert_response :success
    end

    test 'in json without animals' do
      get :new, { procedure_name: 'milking', reference_name: 'mammal_to_milk' }, xhr: true
      assert_response :success
    end
  end
end
