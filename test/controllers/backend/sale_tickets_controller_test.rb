require 'test_helper'
module Backend
  class SaleTicketsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[select attach detach finish detach_gaps]
  end
end
