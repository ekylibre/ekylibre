require 'test_helper'

class Backend::HelpsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: [:show, :toggle]
end
