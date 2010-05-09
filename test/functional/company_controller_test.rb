require 'test_helper'

class CompanyControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :except=>[:unknown_action, :tabbox_index, :formalize, :side, :print], :user_lock=>:delete, :user_unlock=>:delete
end
