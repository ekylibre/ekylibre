require 'test_helper'
module Backend
  class VisualsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :picture
  end
end
