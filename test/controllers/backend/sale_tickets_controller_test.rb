require 'test_helper'
class Backend::SaleTicketsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: [:select, :attach, :detach, :finish]
end
