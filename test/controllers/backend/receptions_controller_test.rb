require 'test_helper'
module Backend
  class ReceptionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions give: :touch
  end
end
