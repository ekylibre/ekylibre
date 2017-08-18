require 'test_helper'

module Backend
  class BuildingDivisionsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :destroy

    test 'destroy action' do
      record = BuildingDivision.find(93)
      assert record.destroyable?
      delete :destroy, id: record.id
      assert_response :redirect
    end
  end
end
