require 'test_helper'

module Backend
  class MyselvesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions show: :index, except: %i[update change_password]
  end
end
