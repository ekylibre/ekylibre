require 'test_helper'
module Backend
  class NotificationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[show notification_icon_class]
  end
end
