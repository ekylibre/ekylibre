require 'test_helper'
module Backend
  class GeneralLedgersControllerTest < ActionController::TestCase
    test_restfully_all_actions only: %i[index]
  end
end
