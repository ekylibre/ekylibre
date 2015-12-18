require 'test_helper'
module Backend
  class NotificationsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :show
  end
end
