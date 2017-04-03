require 'test_helper'
module Backend
  class SaleOpportunitiesControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[select attach detach finish]
  end
end
