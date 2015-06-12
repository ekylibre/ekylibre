require 'test_helper'

class GolumnsControllerTest < ActionController::TestCase
  test "should get update" do
    get :update
    assert_response :success
  end

  test "should get reset" do
    get :reset
    assert_response :success
  end

end
