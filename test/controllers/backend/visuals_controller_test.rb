require 'test_helper'
module Backend
  class VisualsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: :picture
  end
end
