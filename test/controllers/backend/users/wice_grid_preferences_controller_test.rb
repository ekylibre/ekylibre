require 'test_helper'
module Backend
  module Users
    class WiceGridPreferencesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :save_column
    end
  end
end
