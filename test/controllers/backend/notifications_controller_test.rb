require 'test_helper'
class Backend::NotificationsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: :show
end
