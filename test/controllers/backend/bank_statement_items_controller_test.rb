require 'test_helper'
module Backend
  class BankStatementItemsControllerTest < ActionController::TestCase
    # TODO: Re-activate #create, #destroy and #new tests
    test_restfully_all_actions except: %i[create destroy new]
  end
end
