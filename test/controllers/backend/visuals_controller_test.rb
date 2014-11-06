require 'test_helper'
class Backend::VisualsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: :picture
end
