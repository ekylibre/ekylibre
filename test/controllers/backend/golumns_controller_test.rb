require 'test_helper'

class Backend::GolumnsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: [:update, :reset]

  test "should get update" do
    post :update
    assert_response :success
  end

  test "should get reset" do
    post :reset
    assert_response :success
  end

end
