require 'test_helper'
class Backend::AnimalProductsControllerTest < ActionController::TestCase
  test_restfully_all_actions index: :redirect
end
