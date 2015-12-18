require 'test_helper'
module Backend
  class BeehivesControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:update, :reset]
  end
end
