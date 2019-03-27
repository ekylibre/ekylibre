require 'test_helper'
module Backend
  class NamingFormatLandParcelsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[index create update destroy show]

    test 'action index' do
      get :index
      assert_response :success
    end
  end
end
