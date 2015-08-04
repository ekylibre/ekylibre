require 'test_helper'
class PublicControllerTest < ActionController::TestCase
  test 'index' do
    get :index
    assert_response :redirect
  end
end
