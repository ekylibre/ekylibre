require 'test_helper'
module Backend
  class QuickAffairsControllerTest < ActionController::TestCase
    test 'can\'t be accessed since there are no routes to it' do
      assert_raise { get :new }
      assert_raise { post :create }
    end
  end
end
