require 'test_helper'
module Backend
  class ProjectBudgetsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions show: :redirected_get
  end
end
