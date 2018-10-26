require 'test_helper'
module Backend
  class ProjectBudgetsControllerTest < ActionController::TestCase
    test_restfully_all_actions show: :redirected_get
  end
end
