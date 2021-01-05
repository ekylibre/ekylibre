require 'test_helper'
class ApplicationControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
  test_restfully_all_actions except: %i[current_theme current_theme= human_action_name authorized?]
end
