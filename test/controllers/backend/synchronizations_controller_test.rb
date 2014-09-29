require 'test_helper'
class Backend::SynchronizationsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: :update
end
