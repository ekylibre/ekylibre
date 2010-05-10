require 'test_helper'

class CompanyControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :except=>[:unknown_action, :tabbox_index, :formalize, :side, :print, :listing_node_create, :listing_node_update, :listing_node_delete], :user_lock=>:delete, :user_unlock=>:delete, :listing_mail=>:update
end
