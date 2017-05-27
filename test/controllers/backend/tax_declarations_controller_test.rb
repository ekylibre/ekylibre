require 'test_helper'
module Backend
  class TaxDeclarationsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:new]
    # TODO: Add a #new test.
  end
end
