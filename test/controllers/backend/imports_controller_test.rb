require 'test_helper'

class Backend::ImportsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: :run
end
