require 'test_helper'
module Backend
  class SensorsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:detail, :models]

    test 'retrieving models' do
      get :models, format: :json
      get :models, vendor_euid: :openweathermap, format: :json
    end

    # test "retrieving detail" do
    #   get :detail, vendor_euid: :openweathermap, model_euid: :virtual_station, format: :js
    # end
  end
end
