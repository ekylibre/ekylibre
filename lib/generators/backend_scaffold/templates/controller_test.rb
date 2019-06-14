require 'test_helper'

module Backend
  class <%= controller_class_name -%>ControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions
  end
end

