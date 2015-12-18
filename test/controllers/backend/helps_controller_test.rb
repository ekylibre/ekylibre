require 'test_helper'

module Backend
  class HelpsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:show, :toggle]
  end
end
