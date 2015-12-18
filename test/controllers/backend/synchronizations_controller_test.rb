require 'test_helper'
module Backend
  class SynchronizationsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:update, :run]
  end
end
