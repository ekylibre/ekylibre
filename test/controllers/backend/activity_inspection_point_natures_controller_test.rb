require 'test_helper'
module Backend
  class ActivityInspectionPointNaturesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions autocomplete: { column: :name, q: 'Sab' }
  end
end
