require 'test_helper'

module Backend
  class HelpsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[show toggle]
  end
end
