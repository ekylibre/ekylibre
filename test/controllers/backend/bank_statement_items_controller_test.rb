require 'test_helper'
module Backend
  class BankStatementItemsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #create, #destroy and #new tests
    test_restfully_all_actions except: %i[create destroy new]
  end
end
