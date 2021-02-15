require 'test_helper'
module Backend
  class QuickAffairsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test 'can\'t be accessed since there are no routes to it' do
      assert_raise { get(:new, params: {}) }
      assert_raise { post(:create, params: {}) }
    end
  end
end
