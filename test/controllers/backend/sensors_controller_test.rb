require 'test_helper'
module Backend
  class SensorsControllerTest < ActionController::TestCase
    # TODO: Re-activate the following
    test_restfully_all_actions except: %i[detail models retrieve]

    # TODO: Re-activate the following

    # test 'retrieving models' do
    #   get :models, params: { format: :json }
    #   get :models, params: { vendor_euid: :openweathermap, format: :json }
    # end

    # test "retrieving detail" do
    #   get :detail, vendor_euid: :openweathermap, model_euid: :virtual_station, format: :js
    # end
  end
end
