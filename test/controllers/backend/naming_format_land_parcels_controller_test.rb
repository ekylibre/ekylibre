require 'test_helper'
module Backend
  class NamingFormatLandParcelsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[index create update destroy show]

    test 'action index' do
      get :index
      assert_response :success
    end
  end
end
