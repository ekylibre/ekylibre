require 'test_helper'

module Backend
  class IssuesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions close: :touch, reopen: :touch
  end
end
