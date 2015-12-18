require 'test_helper'
module Backend
  class SaleTicketsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:select, :attach, :detach, :finish]
  end
end
