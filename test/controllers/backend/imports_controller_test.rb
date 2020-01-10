require 'test_helper'

module Backend
  class ImportsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: :run, progress: :show
  end
end
