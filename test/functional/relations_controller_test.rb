require 'test_helper'

class RelationsControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :complement_sort=>:delete, :complement_choice_up=>:delete, :complement_choice_down=>:delete, :except=>[:change_minutes]
end
