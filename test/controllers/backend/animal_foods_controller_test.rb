require 'test_helper'
class Backend::AnimalFoodsControllerTest < ActionController::TestCase
  test_restfully_all_actions index: :redirect
end
