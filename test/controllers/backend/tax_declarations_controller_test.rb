require 'test_helper'
module Backend
  class TaxDeclarationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[new]
    # TODO: Add a #new test.
  end
end
